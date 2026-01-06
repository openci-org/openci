import { Button } from '@/components/studio/Button'
import { Container } from '@/components/studio/Container'
import { FadeIn } from '@/components/studio/FadeIn'
import { Offices } from '@/components/studio/Offices'

export function ContactSection() {
  return (
    <Container className="mt-24 sm:mt-32 lg:mt-40">
      <FadeIn className="-mx-6 rounded-4xl bg-neutral-950 px-6 py-20 sm:mx-0 sm:py-32 md:px-12">
        <div className="mx-auto max-w-4xl">
          <div className="max-w-xl">
            <h2 className="font-display text-3xl font-medium text-balance text-white sm:text-4xl">
              お気軽にご相談ください。
              <br />
              何度相談していただいても、
              <br />
              相談料は無料です。
            </h2>
            <div className="mt-6 flex">
              <Button href="https://form.typeform.com/to/XIdO4iES" invert>
                問い合わせ
              </Button>
            </div>
            <div className="mt-10 border-t border-white/10 pt-10">
              <h3 className="font-display text-base font-semibold text-white">
                オフィス
              </h3>
              <Offices
                invert
                className="mt-6 grid grid-cols-1 gap-8 sm:grid-cols-2"
              />
            </div>
          </div>
        </div>
      </FadeIn>
    </Container>
  )
}
