import React from 'react';

const Terms = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white shadow-xl rounded-2xl overflow-hidden">
        <div className="px-8 py-10">
          <h1 className="text-4xl font-extrabold text-gray-900 mb-8 border-b pb-4">Terms of Service</h1>
          <div className="prose prose-blue max-w-none text-gray-600 space-y-6">
            <p className="text-sm text-gray-400 italic">Last Updated: May 15, 2026</p>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">1. Acceptance of Terms</h2>
              <p>By downloading, installing, or using the <strong>Will</strong> mobile application ("the App"), developed and operated by <strong>Lavish</strong> ("we", "us", or "our"), you agree to be bound by these Terms of Service ("Terms") and all applicable laws and regulations. If you do not agree with any of these Terms, you must not use or access the App.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">2. Description of Service</h2>
              <p>The <strong>Will</strong> App is a professional on-demand labour and workforce services platform that connects users ("Customers") with verified service workers ("Workers") for tasks including but not limited to plumbing, electrical work, masonry, carpentry, painting, cleaning, and general labour. The App facilitates booking, communication, real-time tracking, and payment processing between Customers and Workers.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">3. Account Registration</h2>
              <p>To use the App, you must create an account by providing accurate, current, and complete information. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">4. Use License</h2>
              <p>We grant you a limited, non-exclusive, non-transferable, revocable license to download and use the <strong>Will</strong> App on your personal mobile device for personal, non-commercial purposes in accordance with these Terms. You may not:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Modify, copy, or create derivative works based on the App.</li>
                <li>Reverse engineer, decompile, or disassemble the App.</li>
                <li>Use the App for any unlawful purpose or in violation of these Terms.</li>
                <li>Transfer, sublicense, or assign your rights under these Terms to any third party.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">5. Payments and Fees</h2>
              <p>The App facilitates payments between Customers and Workers through Razorpay, a third-party payment processor. A platform commission fee may be charged at the time of booking. All payments are subject to the terms and conditions of the payment processor. We are not responsible for any payment processing errors or disputes with the payment provider.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">6. User Conduct</h2>
              <p>You agree not to:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Provide false, inaccurate, or misleading information.</li>
                <li>Harass, abuse, or harm any other user or service worker.</li>
                <li>Use the App to engage in any fraudulent or illegal activities.</li>
                <li>Interfere with or disrupt the App's functionality or servers.</li>
                <li>Attempt to gain unauthorized access to any part of the App.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">7. Disclaimer of Warranties</h2>
              <p>The <strong>Will</strong> App and its services are provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, either express or implied. We do not guarantee that the App will be uninterrupted, error-free, or free of viruses or other harmful components. We do not guarantee the quality, reliability, or safety of any Workers available through the App.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">8. Limitation of Liability</h2>
              <p>To the fullest extent permitted by applicable law, in no event shall <strong>Lavish</strong> or the <strong>Will</strong> App be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, or goodwill, arising out of or in connection with your use of the App.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">9. Termination</h2>
              <p>We reserve the right to suspend or terminate your account and access to the App at our sole discretion, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, workers, us, or third parties, or for any other reason.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">10. Changes to Terms</h2>
              <p>We may revise these Terms at any time. The updated version will be indicated by an updated "Last Updated" date. Your continued use of the App after any changes constitutes acceptance of the revised Terms.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">11. Governing Law</h2>
              <p>These Terms shall be governed by and construed in accordance with the laws of India. Any disputes arising from these Terms or your use of the App shall be subject to the exclusive jurisdiction of the courts in India.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">12. Contact</h2>
              <p>If you have any questions regarding these Terms, you may contact us at:</p>
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

export default Terms;
