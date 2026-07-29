/// The two legal documents rendered by `LegalScreen`.
///
/// Copy is transcribed verbatim from Figma **Terms of Use Screen**
/// (`1277:32411`) and **Privacy Policy Screen** (`1277:32341`), so this file is
/// the single source of truth for both — no duplication between the auth flow
/// and any later entry point (settings, sign-up).
library;

import 'package:flutter/foundation.dart';

/// One block of body copy inside a [LegalSection]: a paragraph or a bullet
/// list. Sections mix the two (a lead-in sentence followed by bullets).
@immutable
sealed class LegalBlock {
  const LegalBlock();
}

/// A run of prose.
@immutable
final class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text, {this.trailingBold});

  final String text;

  /// Appended after [text] in semibold `content/secondary` — used for the
  /// contact address that closes each document.
  final String? trailingBold;
}

/// A `list-disc` group. Sub-bullets are flagged on the item rather than nested
/// in a child list, because the design only ever goes one level deep.
@immutable
final class LegalBullets extends LegalBlock {
  const LegalBullets(this.items);

  final List<LegalBullet> items;
}

@immutable
final class LegalBullet {
  const LegalBullet(this.text, {this.lead, this.nested = false});

  final String text;

  /// Semibold run before [text] — e.g. "Eligibility:". Absent on the plain
  /// bullet lists (Terms §5, Privacy §5).
  final String? lead;

  /// Indented one level further. Only Terms §3 (SkillCoins) uses this.
  final bool nested;
}

@immutable
final class LegalSection {
  const LegalSection({required this.heading, required this.blocks});

  final String heading;
  final List<LegalBlock> blocks;
}

@immutable
final class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  /// Nav-bar title.
  final String title;
  final String lastUpdated;

  /// Unnumbered opening paragraph, above section 1.
  final String intro;
  final List<LegalSection> sections;
}

/// Figma **Terms of Use Screen** — `1277:32411`.
const termsOfUse = LegalDocument(
  title: 'Terms of Use',
  lastUpdated: 'Last Updated May 24th, 2026',
  intro:
      'Welcome to Skiflux. By downloading, accessing, or using the Skiflux '
      'mobile application or website (the "Platform"), you agree to be bound '
      'by these Terms of Use ("Terms"). If you do not agree to these Terms, '
      'do not use the Platform.',
  sections: [
    LegalSection(
      heading: '1. The Skiflux Ecosystem',
      blocks: [
        LegalParagraph(
          'Skiflux is a gamified skill economy and learning platform. We '
          'provide educational content, practical execution tasks, exams, and '
          'a marketplace. Our core philosophy is "Execution Over Theory," '
          'meaning your reputation on the Platform is built solely on '
          'verifiable work.',
        ),
      ],
    ),
    LegalSection(
      heading: '2. User Accounts & Identity',
      blocks: [
        LegalBullets([
          LegalBullet(
            'You must be at least 16 years old to use the Platform.',
            lead: 'Eligibility:',
          ),
          LegalBullet(
            'You agree to provide accurate, current, and complete information '
            'during registration.',
            lead: 'Accuracy of Information:',
          ),
          LegalBullet(
            'To prevent fraud, the name on your Skiflux profile must exactly '
            'match the name on the bank account you connect for SkillCoin '
            'withdrawals. Skiflux reserves the right to reject withdrawals if '
            'names do not match.',
            lead: 'Bank Account Matching:',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '3. The Gamified Economy (XP, Badges & SkillCoins)',
      blocks: [
        LegalParagraph(
          'Skiflux operates a dual-system economy consisting of Status (XP) '
          'and Currency (SkillCoins).',
        ),
        LegalBullets([
          LegalBullet(
            'XP and Badges represent your status, rank, and verified skills. '
            'XP cannot be purchased. It can only be earned by completing '
            'learning episodes, passing exams, and submitting approved '
            'project tasks. Skiflux reserves the right to revoke XP or Badges '
            'if it is discovered that a task was completed fraudulently or '
            'via plagiarism.',
            lead: 'Execution Points (XP) & Badges:',
          ),
          LegalBullet(
            'SkillCoins are the digital currency of the Platform.',
            lead: 'SkillCoins:',
          ),
          LegalBullet(
            'SkillCoins can be earned by completing specific platform tasks, '
            'or purchased via fiat currency using our integrated payment '
            'gateways.',
            lead: 'Earning & Buying:',
            nested: true,
          ),
          LegalBullet(
            'Earned SkillCoins may be converted to fiat currency and '
            'withdrawn to your verified bank account, subject to minimum '
            'withdrawal limits and processing times (up to 24 hours).',
            lead: 'Withdrawals:',
            nested: true,
          ),
          LegalBullet(
            'SkillCoins hold no value outside the Skiflux Platform and cannot '
            'be transferred to other users outside of official Marketplace '
            'transactions.',
            lead: 'Non-Transferable:',
            nested: true,
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '4. Task Submissions & "Proof of Work"',
      blocks: [
        LegalBullets([
          LegalBullet(
            'By submitting a project link (e.g., Figma, GitHub) or uploading '
            'a file as a task submission, you represent and warrant that the '
            'work is entirely your own. Plagiarism will result in immediate '
            'task rejection, loss of XP, and potential account suspension.',
            lead: 'Originality:',
          ),
          LegalBullet(
            'By submitting tasks that achieve a passing grade, you grant '
            'Skiflux a non-exclusive, worldwide, royalty-free license to '
            'display this work on your public Skiflux profile as "Proof of '
            'Work" to potential employers or clients.',
            lead: 'Right to Display:',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '5. Prohibited Conduct',
      blocks: [
        LegalParagraph('You agree NOT to:'),
        LegalBullets([
          LegalBullet(
            'Use automated scripts, bots, or cheats to artificially inflate '
            'your XP, watch time, or SkillCoin balance.',
          ),
          LegalBullet(
            'Upload malicious files, viruses, or inappropriate content in the '
            'task submission portals.',
          ),
          LegalBullet(
            'Harass, abuse, or spam other users in the comment sections or '
            'community hubs.',
          ),
          LegalBullet(
            "Attempt to reverse-engineer or hack the Platform's gamification "
            'systems.',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '6. Termination & Suspension',
      blocks: [
        LegalParagraph(
          'Skiflux reserves the right, at our sole discretion, to suspend, '
          'disable, or terminate your account at any time, without prior '
          'notice, if you violate these Terms, engage in fraudulent financial '
          'activity, or submit plagiarized work.',
        ),
      ],
    ),
    LegalSection(
      heading: '7. Limitation of Liability',
      blocks: [
        LegalParagraph(
          'To the maximum extent permitted by law, Skiflux shall not be liable '
          'for any indirect, incidental, special, consequential, or punitive '
          'damages, or any loss of profits or revenues, whether incurred '
          'directly or indirectly, or any loss of data, use, goodwill, or '
          'other intangible losses resulting from your access to or use of '
          'the Platform.',
        ),
      ],
    ),
    LegalSection(
      heading: '8. Changes to the Terms',
      blocks: [
        LegalParagraph(
          'We may modify these Terms at any time. We will notify you of '
          'significant changes via the Platform or email. Your continued use '
          'of the Platform after such modifications constitutes your '
          'acceptance of the updated Terms.',
        ),
      ],
    ),
    LegalSection(
      heading: '9. Contact Us',
      blocks: [
        LegalParagraph(
          'For any inquiries regarding these Terms, please contact us via the '
          'in-app Help Centre or at: ',
          trailingBold: 'legal@skiflux.com',
        ),
      ],
    ),
  ],
);

/// Figma **Privacy Policy Screen** — `1277:32341`.
const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  lastUpdated: 'Last Updated May 24th, 2026',
  intro:
      'Welcome to Skiflux ("we," "our," or "us"). We respect your privacy and '
      'are committed to protecting your personal data. This Privacy Policy '
      'explains how we collect, use, disclose, and safeguard your information '
      'when you use the Skiflux mobile application and website (the '
      '"Platform").',
  sections: [
    LegalSection(
      heading: '1. Information We Collect',
      blocks: [
        LegalParagraph(
          'We collect information that identifies, relates to, or could '
          'reasonably be linked to you ("Personal Data").',
        ),
        LegalBullets([
          LegalBullet(
            'When you create an account, we collect your name, email address, '
            'username (@handle), profile picture, and password.',
            lead: 'Account Information:',
          ),
          LegalBullet(
            'To process the purchase of SkillCoins or facilitate withdrawals, '
            'we collect payment card details and bank account information. '
            'Note: Payment processing is handled by secure, third-party '
            'payment gateways. We do not store your full credit card numbers '
            'on our servers.',
            lead: 'Financial Information:',
          ),
          LegalBullet(
            'As a "Proof-of-Work" platform, we collect data regarding your '
            'watch history, task submissions (links, files), exam scores, '
            'earned XP, acquired badges, and SkillCoin balance.',
            lead: 'Performance & Execution Data:',
          ),
          // The Figma text run ends with a stray fragment of onboarding copy
          // ("…earning to active earning. The Skiflux ecosystem is ready for
          // you.") pasted in by mistake. Dropped rather than propagated.
          LegalBullet(
            'We collect information about how you access the Platform, '
            'including device type, operating system, IP address, and '
            'interaction metrics (e.g., clicks, time spent on episodes).',
            lead: 'Device & Usage Data:',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '2. How We Use Your Information',
      blocks: [
        LegalParagraph(
          'We use your Personal Data to operate the Skiflux ecosystem '
          'efficiently:',
        ),
        LegalBullets([
          LegalBullet(
            'Creating your account, delivering learning content, grading '
            'tasks, and awarding XP and SkillCoins.',
            lead: 'To Provide the Service:',
          ),
          LegalBullet(
            'Displaying your verified skills, badges, leaderboard ranking, '
            'and portfolio tasks to potential employers or clients (subject '
            'to your privacy settings).',
            lead: 'To Build Your Public Profile:',
          ),
          LegalBullet(
            'Facilitating the purchase of SkillCoins and processing fiat '
            'withdrawals to your verified bank account.',
            lead: 'To Process Transactions:',
          ),
          LegalBullet(
            'Analyzing user behavior to optimize the UI, learning curriculum, '
            'and matching algorithms for the Marketplace.',
            lead: 'To Improve the Platform:',
          ),
          LegalBullet(
            'Sending transactional emails, platform updates, and '
            'notifications about your task reviews or gig matches.',
            lead: 'To Communicate:',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '3. How We Share Your Information',
      blocks: [
        LegalParagraph(
          'We do not sell your personal data. We only share your information '
          'in the following circumstances:',
        ),
        LegalBullets([
          LegalBullet(
            'By default, your Skiflux profile acts as a verified CV. Your '
            'Username, Avatar, Badges, League, and Verified Tasks may be '
            'visible to the public. You can control profile visibility '
            '(Public vs. Private) in your Account Settings.',
            lead: 'Publicly (Your Skiflux Profile):',
          ),
          LegalBullet(
            'We share necessary data with trusted third parties who assist us '
            'with payment processing, cloud hosting, and data analytics.',
            lead: 'With Service Providers:',
          ),
          LegalBullet(
            'We may disclose your information if required by law, subpoena, '
            'or other legal processes.',
            lead: 'Legal Compliance:',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '4. Data Security',
      blocks: [
        LegalParagraph(
          'We implement industry-standard security measures, including '
          'encryption and secure socket layer (SSL) technology, to protect '
          'your Personal Data. However, no method of transmission over the '
          'internet is 100% secure, and we cannot guarantee absolute '
          'security.',
        ),
      ],
    ),
    LegalSection(
      heading: '5. Your Rights & Choices',
      blocks: [
        LegalParagraph(
          'Depending on your location, you may have the right to:',
        ),
        LegalBullets([
          LegalBullet(
            'Access the Personal Data we hold about you (Data Export).',
          ),
          LegalBullet('Request correction of inaccurate data.'),
          LegalBullet('Delete your account and associated data.'),
          LegalBullet(
            'Opt-out of certain data tracking (e.g., personalized '
            'recommendations). You can exercise these rights directly within '
            'the Skiflux App Settings under "Privacy & Data."',
          ),
        ]),
      ],
    ),
    LegalSection(
      heading: '6. Contact Us',
      blocks: [
        LegalParagraph(
          'If you have any questions about this Privacy Policy, please '
          'contact us at: ',
          trailingBold: 'support@skiflux.com',
        ),
      ],
    ),
  ],
);
