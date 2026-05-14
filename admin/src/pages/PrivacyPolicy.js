import React from 'react';

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white shadow-xl rounded-2xl overflow-hidden">
        <div className="px-8 py-10">
          <h1 className="text-4xl font-extrabold text-gray-900 mb-8 border-b pb-4">Privacy Policy</h1>
          <div className="prose prose-blue max-w-none text-gray-600 space-y-6">
            <p className="text-sm text-gray-400 italic">Last Updated: May 15, 2026</p>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">1. Introduction</h2>
              <p>Welcome to <strong>Will</strong> ("the App"). Will is a professional on-demand labour and workforce services application developed and operated by <strong>Lavish</strong> ("we", "us", or "our"). We are committed to protecting your personal information and your right to privacy.</p>
              <p>This Privacy Policy describes how we collect, use, disclose, and safeguard your information when you use the <strong>Will</strong> mobile application, available on the Google Play Store. Please read this policy carefully. If you do not agree with the terms of this Privacy Policy, please do not access the App.</p>
              <p>If you have any questions or concerns about this policy or our practices, please contact us at <strong>templavish9@gmail.com</strong>.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">2. Information We Collect</h2>
              <p>We collect personal information that you voluntarily provide to us when you register on the App, express an interest in obtaining information about us or our products and services, participate in activities on the App, or otherwise contact us.</p>
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Personal Information Provided by You</h3>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>Account Information:</strong> Name, phone number, email address, and profile picture.</li>
                <li><strong>Authentication Data:</strong> Login credentials, Google Sign-In tokens.</li>
                <li><strong>Service Booking Data:</strong> Task descriptions, images, voice notes, and text instructions you provide when creating service requests.</li>
                <li><strong>Payment Information:</strong> Transaction IDs and payment status processed through Razorpay (we do not store your card details directly).</li>
                <li><strong>Communication Data:</strong> Messages exchanged with service workers through the in-app chat feature.</li>
              </ul>
              <h3 className="text-xl font-semibold text-gray-700 mb-2 mt-4">Information Collected Automatically</h3>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>Location Data:</strong> We request access to and track location-based information from your mobile device (both fine and coarse location) to provide location-based services, match you with nearby workers, and display your service address.</li>
                <li><strong>Device Data:</strong> Device information such as your mobile device ID, model, manufacturer, and operating system version.</li>
                <li><strong>Push Notification Tokens:</strong> Firebase Cloud Messaging (FCM) tokens to send you service updates and booking notifications.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">3. How We Use Your Information</h2>
              <p>We use personal information collected via the <strong>Will</strong> App for the following legitimate business purposes:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>To facilitate account creation and the login process, including Google Sign-In.</li>
                <li>To connect you with qualified, verified service workers based on your location and service requirements.</li>
                <li>To process and manage your service bookings, including scheduling, pricing, and payment processing.</li>
                <li>To enable real-time communication between you and assigned workers via in-app chat.</li>
                <li>To send you push notifications about booking status updates, worker assignments, and service reminders.</li>
                <li>To provide customer support and respond to your inquiries.</li>
                <li>To maintain and improve the App's functionality, performance, and user experience.</li>
                <li>To enforce our terms, conditions, and policies for business purposes.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">4. Sharing Your Information</h2>
              <p>We may share your information in the following situations:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>With Service Workers:</strong> Your name, location, task description, and contact information are shared with the worker assigned to your booking to enable service delivery.</li>
                <li><strong>With Payment Processors:</strong> Transaction data is shared with Razorpay for secure payment processing.</li>
                <li><strong>For Legal Compliance:</strong> We may disclose your information where required to comply with applicable law, governmental requests, a judicial proceeding, court order, or legal process.</li>
                <li><strong>With Your Consent:</strong> We may share your information for any other purpose with your explicit consent.</li>
              </ul>
              <p>We do <strong>not</strong> sell, rent, or trade your personal information to third parties for marketing purposes.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">5. Data Retention</h2>
              <p>We retain your personal information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. When you delete your account, your data is removed from our active databases within 30 days and from backup systems within 90 days.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">6. Data Security</h2>
              <p>We implement appropriate technical and organizational security measures to protect your personal information. However, no electronic transmission or storage method is 100% secure, and we cannot guarantee absolute security.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">7. Your Privacy Rights</h2>
              <p>You have the right to:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>Access and Update:</strong> View and update your profile information through the App's Profile and Manage Profile screens.</li>
                <li><strong>Delete Your Account:</strong> Request deletion of your account and associated data via the in-app "Delete Account" option or by emailing us.</li>
                <li><strong>Opt-out of Notifications:</strong> Disable push notifications through your device settings.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">8. Children's Privacy</h2>
              <p>The <strong>Will</strong> App is not intended for individuals under the age of 18. We do not knowingly collect personal information from children. If we become aware that a child under 18 has provided us with personal data, we will take steps to delete such information promptly.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">9. Changes to This Privacy Policy</h2>
              <p>We may update this Privacy Policy from time to time. The updated version will be indicated by an updated "Last Updated" date. We encourage you to review this Privacy Policy periodically to stay informed about how we protect your information.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">10. Contact Us</h2>
              <p>If you have questions, concerns, or requests regarding this Privacy Policy or our data practices, you may contact us at:</p>
              <ul className="list-none pl-0 space-y-1 mt-2">
                <li><strong>Developer:</strong> Lavish</li>
                <li><strong>App Name:</strong> Will</li>
                <li><strong>Email:</strong> <span className="text-blue-600">templavish9@gmail.com</span></li>
              </ul>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
