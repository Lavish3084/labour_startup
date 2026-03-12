import React from 'react';

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white shadow-xl rounded-2xl overflow-hidden">
        <div className="px-8 py-10">
          <h1 className="text-4xl font-extrabold text-gray-900 mb-8 border-b pb-4">Privacy Policy</h1>
          <div className="prose prose-blue max-w-none text-gray-600 space-y-6">
            <p className="text-sm text-gray-400 italic">Last Updated: March 12, 2026</p>
            
            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">1. Introduction</h2>
              <p>Welcome to Labour. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about our policy, or our practices with regards to your personal information, please contact us.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">2. Information We Collect</h2>
              <p>We collect personal information that you voluntarily provide to us when you register on the App, express an interest in obtaining information about us or our products and Services, when you participate in activities on the App or otherwise when you contact us.</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Personal Information: Name, phone number, email address, and profile picture.</li>
                <li>Location Data: We request access or permission to and track location-based information from your mobile device to provide services based on your location.</li>
                <li>Device Data: Device information, such as your mobile device ID, model, and manufacturer.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">3. How We Use Your Information</h2>
              <p>We use personal information collected via our App for a variety of business purposes described below:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>To facilitate account creation and logon process.</li>
                <li>To post testimonials.</li>
                <li>To request feedback.</li>
                <li>To enable user-to-user communications.</li>
                <li>To provide services (connecting workers with users).</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">4. Sharing Your Information</h2>
              <p>We only share information with your consent, to comply with laws, to provide you with services, to protect your rights, or to fulfill business obligations.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">5. Contact Us</h2>
              <p>If you have questions or comments about this policy, you may email us at support@lavish3084.com or by post to our office address.</p>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
