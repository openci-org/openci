import { Container } from '@/marketing-components/container'
import { Footer } from '@/marketing-components/footer'
import { GradientBackground } from '@/marketing-components/gradient'
import { Navbar } from '@/marketing-components/navbar'
import { Heading } from '@/marketing-components/text'

export default async function PrivacyPolicy() {
  return (
    <main className="overflow-hidden">
      <GradientBackground />
      <Container>
        <Navbar />
      </Container>
      <div className="m-16" />
      <Body />
      <Footer />
    </main>
  )
}

function Body() {
  return (
    <Container>
      <section id="privacy-policy" className="scroll-mt-8">
        <Heading as="div" className="mt-2 text-center">
          Privacy Policy
        </Heading>
        <p className="mx-auto mt-8 max-w-xl text-sm text-gray-600">
          Last updated: December 30, 2025
        </p>
        <div className="mx-auto mt-16 mb-32 max-w-xl space-y-12">
          <dl>
            <dt className="text-sm font-semibold">1. Introduction</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              OpenCI Inc. (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;)
              is committed to protecting your privacy. This Privacy Policy
              explains how we collect, use, disclose, and safeguard your
              information when you use our CI/CD platform and related services.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">2. Information We Collect</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We may collect the following types of information:
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>
                  Account information: name, email address, and payment details
                </li>
                <li>
                  Usage data: logs, build configurations, and performance
                  metrics
                </li>
                <li>
                  Device information: IP address, browser type, and operating
                  system
                </li>
                <li>
                  Repository data: code and configuration files you choose to
                  integrate with our services
                </li>
              </ul>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">
              3. How We Use Your Information
            </dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We use the collected information to:
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>Provide, maintain, and improve our services</li>
                <li>Process transactions and send related information</li>
                <li>
                  Send technical notices, updates, and administrative messages
                </li>
                <li>Respond to your comments, questions, and support needs</li>
                <li>
                  Monitor and analyze usage patterns to enhance user experience
                </li>
                <li>
                  Detect, prevent, and address technical issues and security
                  threats
                </li>
              </ul>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">4. Information Sharing</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We do not sell your personal information. We may share your
              information only in the following circumstances:
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>
                  With service providers who assist in operating our platform
                </li>
                <li>To comply with legal obligations or court orders</li>
                <li>
                  To protect the rights, property, or safety of OpenCI Inc., our
                  users, or others
                </li>
                <li>
                  In connection with a merger, acquisition, or sale of assets
                </li>
              </ul>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">5. Data Security</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We implement appropriate technical and organizational measures to
              protect your information against unauthorized access, alteration,
              disclosure, or destruction. This includes encryption, secure data
              centers, access controls, and regular security audits.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">6. Data Retention</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We retain your information for as long as your account is active
              or as needed to provide services. We may also retain and use your
              information to comply with legal obligations, resolve disputes,
              and enforce our agreements.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">7. Your Rights</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              Depending on your location, you may have the right to:
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>Access, correct, or delete your personal information</li>
                <li>Object to or restrict certain processing activities</li>
                <li>Request data portability</li>
                <li>Withdraw consent where processing is based on consent</li>
              </ul>
              To exercise these rights, please contact us at support@openci.org.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">
              8. Cookies and Tracking Technologies
            </dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We use cookies and similar technologies to collect usage data,
              remember your preferences, and improve our services. You can
              manage cookie preferences through your browser settings.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">9. Changes to This Policy</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We may update this Privacy Policy from time to time. We will
              notify you of any changes by posting the new policy on this page
              and updating the &quot;Last updated&quot; date.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">10. Contact Us</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              If you have any questions about this Privacy Policy, please
              contact us at:
              <br />
              <br />
              OpenCI Inc.
              <br />
              Email: support@openci.org
            </dd>
          </dl>
        </div>
      </section>
    </Container>
  )
}
