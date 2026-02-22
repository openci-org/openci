import { Container } from "@/components/container";
import { Footer } from "@/components/footer";
import { GradientBackground } from "@/components/gradient";
import { Navbar } from "@/components/navbar";
import { Heading } from "@/components/text";

export default async function TermsOfService() {
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
  );
}

function Body() {
  return (
    <Container>
      <section id="terms-of-service" className="scroll-mt-8">
        <Heading as="div" className="mt-2 text-center">
          Terms of Service
        </Heading>
        <p className="mx-auto mt-8 max-w-xl text-sm text-gray-600">
          Last updated: February 22, 2026
        </p>
        <div className="mx-auto mt-16 mb-32 max-w-xl space-y-12">
          <dl>
            <dt className="text-sm font-semibold">1. Acceptance of Terms</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              By accessing or using the services provided by OpenCI Inc. (&quot;we,&quot;
              &quot;our,&quot; or &quot;us&quot;), you agree to be bound by these Terms of Service.
              If you do not agree to these terms, please do not use our services.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">2. Description of Service</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              OpenCI Inc. provides a CI/CD (Continuous Integration/Continuous Deployment) platform
              designed for iOS and macOS app development. Our services include automated build
              processes, testing, and deployment tools accessible through our web interface and
              APIs.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">3. Account Registration</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              To use our services, you must create an account. You agree to:
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>Provide accurate and complete registration information</li>
                <li>Maintain the security of your account credentials</li>
                <li>Notify us immediately of any unauthorized use of your account</li>
                <li>Accept responsibility for all activities under your account</li>
              </ul>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">4. Acceptable Use</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              You agree not to use our services to:
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>Violate any applicable laws or regulations</li>
                <li>Infringe on intellectual property rights of others</li>
                <li>Distribute malware, viruses, or other harmful software</li>
                <li>
                  Attempt to gain unauthorized access to our systems or other users&apos; accounts
                </li>
                <li>Use our services for any illegal or unauthorized purpose</li>
              </ul>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">5. Intellectual Property</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              You retain all rights to your code, data, and content that you upload to our platform.
              By using our services, you grant us a limited license to process your content solely
              to provide the services. We retain all rights to our platform, software, and related
              intellectual property.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">6. Subscriptions, Payment, and Billing</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              <p>
                Paid services are billed in advance on a subscription basis. You agree to pay all
                fees associated with your selected plan.
              </p>
              <ul className="mt-2 ml-4 list-disc space-y-1">
                <li>
                  <strong>Auto-Renewal:</strong> Subscriptions automatically renew at the end of
                  each billing period (monthly or annually) unless canceled at least 24 hours before
                  the end of the current period.
                </li>
                <li>
                  <strong>Billing:</strong> Payment will be charged to your Apple ID account at
                  confirmation of purchase. Your account will be charged for renewal within 24 hours
                  prior to the end of the current period.
                </li>
                <li>
                  <strong>Cancellation:</strong> You can cancel your subscription at any time
                  through your Apple ID account settings. Cancellation takes effect at the end of
                  the current billing period. No partial refunds are provided for the remaining
                  period.
                </li>
                <li>
                  <strong>Free Trials:</strong> If a free trial is offered, any unused portion of
                  the trial period will be forfeited when you purchase a subscription.
                </li>
                <li>
                  <strong>Price Changes:</strong> We reserve the right to modify pricing with
                  reasonable notice. Price changes will take effect at the start of the next
                  subscription period following the date of the price change.
                </li>
              </ul>
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">7. Refund Policy</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              Subscription fees are non-refundable except as required by applicable law. Since
              subscriptions are managed through Apple, all refund requests must be submitted through
              Apple&apos;s support channels. For more information, visit{" "}
              <a
                href="https://support.apple.com/en-us/HT204084"
                className="text-blue-600 underline"
                target="_blank"
                rel="noopener noreferrer"
              >
                Apple&apos;s refund page
              </a>
              .
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">8. Service Availability and Modifications</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We strive to maintain high availability but do not guarantee uninterrupted service. We
              may modify, suspend, or discontinue any part of our services at any time with
              reasonable notice. We are not liable for any modification, suspension, or
              discontinuation of services.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">9. Limitation of Liability</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              To the maximum extent permitted by law, OpenCI Inc. shall not be liable for any
              indirect, incidental, special, consequential, or punitive damages, including loss of
              profits, data, or business opportunities, arising from your use of our services.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">10. Indemnification</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              You agree to indemnify and hold harmless OpenCI Inc. and its officers, directors,
              employees, and agents from any claims, damages, losses, or expenses arising from your
              use of our services or violation of these terms.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">11. Termination</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              Either party may terminate this agreement at any time. We may suspend or terminate
              your access immediately if you violate these terms. Upon termination, your right to
              use our services ceases, and we may delete your data after a reasonable retention
              period. Termination of your account does not automatically cancel your subscription.
              You must cancel your subscription through your Apple ID account settings before or
              after termination to avoid further charges.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">12. Governing Law</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              These Terms of Service shall be governed by and construed in accordance with the laws
              of Japan. Any disputes arising from these terms shall be subject to the exclusive
              jurisdiction of the Tokyo District Court.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">13. Changes to Terms</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              We may update these Terms of Service from time to time. We will notify you of any
              material changes by posting the new terms on this page and updating the &quot;Last
              updated&quot; date. Continued use of our services after changes constitutes acceptance
              of the new terms.
            </dd>
          </dl>
          <dl>
            <dt className="text-sm font-semibold">14. Contact Us</dt>
            <dd className="mt-4 text-sm/6 text-gray-600">
              If you have any questions about these Terms of Service, please contact us at:
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
  );
}
