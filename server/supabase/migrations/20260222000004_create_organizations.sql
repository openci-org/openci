-- organizations: top-level tenant unit

CREATE TABLE public.organizations (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                    text        NOT NULL,
  slug                    text        NOT NULL UNIQUE,
  -- Stripe (future): NULL until customer is created
  stripe_customer_id      text,
  stripe_subscription_id  text,
  -- Feature flag: false = free tier, true = paid (set by Stripe webhook)
  billing_enabled         boolean     NOT NULL DEFAULT false,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_organizations_slug ON public.organizations(slug);

CREATE TRIGGER organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- org_members: user <-> organization many-to-many with role
CREATE TABLE public.org_members (
  id         uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     uuid     NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id    uuid     NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role       org_role NOT NULL DEFAULT 'member',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, user_id)
);

CREATE INDEX idx_org_members_user_id ON public.org_members(user_id);
CREATE INDEX idx_org_members_org_id  ON public.org_members(org_id);

CREATE TRIGGER org_members_updated_at
  BEFORE UPDATE ON public.org_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- org_invitations: pending email invites (Supabase Auth invite flow)
CREATE TABLE public.org_invitations (
  id          uuid              PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid              NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  invited_by  uuid              NOT NULL REFERENCES auth.users(id),
  email       text              NOT NULL,
  role        org_role          NOT NULL DEFAULT 'member',
  token       text              NOT NULL UNIQUE DEFAULT replace(gen_random_uuid()::text, '-', ''),
  status      invitation_status NOT NULL DEFAULT 'pending',
  expires_at  timestamptz       NOT NULL DEFAULT (now() + interval '7 days'),
  created_at  timestamptz       NOT NULL DEFAULT now(),
  updated_at  timestamptz       NOT NULL DEFAULT now()
);

CREATE INDEX idx_org_invitations_email  ON public.org_invitations(email);
CREATE INDEX idx_org_invitations_org_id ON public.org_invitations(org_id);
CREATE INDEX idx_org_invitations_token  ON public.org_invitations(token);

CREATE TRIGGER org_invitations_updated_at
  BEFORE UPDATE ON public.org_invitations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create a personal org when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user_org()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_slug text;
  v_name text;
  v_org_id uuid;
BEGIN
  v_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
  -- Generate a unique slug from email prefix
  v_slug := lower(regexp_replace(split_part(NEW.email, '@', 1), '[^a-z0-9]', '-', 'g'));

  -- Ensure slug uniqueness by appending a short random suffix if needed
  WHILE EXISTS (SELECT 1 FROM public.organizations WHERE slug = v_slug) LOOP
    v_slug := v_slug || '-' || substr(md5(random()::text), 1, 4);
  END LOOP;

  INSERT INTO public.organizations (name, slug)
  VALUES (v_name || '''s Organization', v_slug)
  RETURNING id INTO v_org_id;

  INSERT INTO public.org_members (org_id, user_id, role)
  VALUES (v_org_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created_org
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_org();
