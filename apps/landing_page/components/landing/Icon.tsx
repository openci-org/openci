import Image from "next/image";
import brand from "../../../website/public/favicon.png";
import { icons, marketingIcons } from "../../../website/src/lib/icons";

export function Icon({ name, marketing = false }: { name: string; marketing?: boolean }) {
  return (
    <svg
      className={marketing ? "icon" : "d-icon"}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      dangerouslySetInnerHTML={{ __html: (marketing ? marketingIcons : icons)[name] }}
    />
  );
}

export function BrandMark() {
  return <Image src={brand} alt="" width={26} height={26} />;
}
