# Quizzy - Educational Game Platform Specification

## Core Concepts

### Authentication & Identity
- Integration with Internet Identity (II):
  - Secure authentication flow
  - Principal-based user identification
  - Multiple device support
  - Session management
  - Device linking/unlinking

### Player Profile
- Each player has:
  - A unique identifier and display name
  - Progress in the subject tree starting from root
  - Inventory of purchased items
  - Achievement tracking
  - Preferences

### Subjects and Progression
- Single-root hierarchical subject system:
  - Root "Quizzy" subject (game root)
    - Contains global XP, level, and credits
    - Core subjects (Math, Physics, etc.) as direct children
    - System-managed, cannot be modified by users
  - Core subjects (e.g., Math, Physics)
    - System-defined subjects
    - Sub-subjects (e.g., under Math: Algebra, Geometry)
    - User-created subjects can be added at this level or below
  - All subjects inherit core mechanics:
    - Level progression
    - XP tracking
    - Subject-specific currency
    - Achievement tree
- Progress aggregation:
  - XP flows upward through the tree:
    - Child XP contributes to parent XP based on multiplier
    - Example: 100 XP in Algebra (0.8 multiplier) = 80 XP to Math
    - Multiple children sum up: (Algebra + Geometry) XP flows to Math
    - Root receives weighted contributions from all core subjects
  - Level calculations:
    - Each subject has its own level thresholds
    - Parent levels consider both direct XP and aggregated child XP
    - Example progression:
      Level 1: 0-100 XP
      Level 2: 101-250 XP
      Level 3: 251-500 XP
      Level scaling continues exponentially
  - Currency system:
    - Credits (root currency):
      - Only earned through core/system subject quests
      - Global currency for store purchases
      - Cannot be awarded by custom subjects
      - Used for marketplace transactions
    - Custom currencies:
      - Created by content creators for their subjects
      - Named by the creator (e.g., "Class Points", "Homework Stars")
      - Only valid within the creator's subject
      - No conversion to Credits or other currencies
      - Can be used for:
        - Subject-specific rewards
        - Custom power-ups
        - Special content unlocks
        - Achievement rewards
      - Multiple currencies per subject allowed
      - Tracked independently per student

### Quest System
- Quests are individual challenges within subjects
- Quest properties:
  - Subject association
  - Difficulty level (1-10)
  - Level requirement
  - XP reward
  - Credit reward
  - Time limit (optional)
  - Question type (multiple choice, numeric input, etc.)
  - Visual aids/animations (optional)
  - Sound effects (optional)

### Quest Generation
#### Mathematics (Initial Focus)
- Algorithmic generation of questions:
  - Basic arithmetic (Level 1-2)
  - Fractions and decimals (Level 3-4)
  - Basic algebra (Level 5-6)
  - Advanced topics (Level 7+)
- Question templates with variable substitution
- Difficulty scaling through:
  - Number complexity
  - Steps required
  - Concept combinations

#### Future Subjects
- Physics: Formula-based generation similar to math
- Geography/Biology: Predefined question banks with randomization
- Support for manually created questions in all subjects

### Gameplay Mechanics
- Quest attempt flow:
  1. Player selects subject and difficulty
  2. System presents appropriate quest
  3. Timer starts (if applicable)
  4. Player submits answer
  5. Immediate feedback provided
  6. XP/Credits awarded on success
  7. Option to retry on failure (with new question)

### Reward System
- XP System:
  - Subject-specific XP gains
  - Master XP as weighted sum of subject XP
  - Level thresholds with increasing requirements
- Currency System:
  - Global credits for general store items
  - Subject-specific currencies:
    - Earned through subject-specific quests
    - Used for subject-specific power-ups and items
    - Bonus currency for mastery achievements
    - Special currency rewards for difficult quests
- Credits:
  - Earned through completing quests
  - Bonus for first-time completion
  - Streak bonuses
  - Daily challenges

### Store and Items
- Cosmetic items
- Power-ups (e.g., extra time, hints)
- Special quest unlocks
- Custom avatars/badges

### Social Features (Future)
- Leaderboards:
  - Global ranking
  - Subject-specific rankings
  - Weekly/Monthly competitions
- Chat lobby
- Friend system
- Achievement sharing

### User Roles and Permissions
- Player: Standard game access and progression
- Content Creator (Parent/Teacher/Mentor):
  - Can create private subjects and quests
  - Can create and manage access groups
  - Can assign content access to:
    - Individual principals
    - Groups of principals
    - Public access (optional)
  - Can set XP and credit rewards
  - Can track assigned players' progress
  - Can create custom achievement milestones

### Access Control System
- Group Management:
  - Teachers can create named groups (e.g., "Class 10A 2024")
  - Groups contain sets of Internet Identity principals
  - Bulk import of principals (e.g., from class roster)
  - Groups can be:
    - Time-limited (e.g., for school year)
    - Archived for record keeping
    - Cloned for new classes
- Access Rights:
  - Granular control at subject and quest levels
  - Multiple access levels:
    - View/Attempt
    - Submit
    - Review others' work (e.g., peer review)
  - Access can be granted to:
    - Individual principals
    - Groups
    - Multiple groups (e.g., all 10th grade classes)
    - Public (optional)
  - Inheritance of access rights through subject tree
  - Time-based access control (e.g., homework available dates)

### Custom Content Creation
- Private Subject Creation:
  - Custom subject name and description
  - Can be created as a sub-subject of any existing subject
  - Inherits properties from parent subject (optional)
  - Custom difficulty scale
  - Optional prerequisites
  - Visibility controls:
    - Private (creator's assigned players only)
    - Public (available to all players)
    - Shared (available to specific content creators)
  - Custom achievement definitions
  - Custom power-ups specific to the subject

- Custom Quest Creation:
  - Question types supported:
    - Multiple choice
    - Text input
    - Numeric input
    - File upload (e.g., for homework submissions)
    - Image-based questions
  - Customizable rewards:
    - XP rewards (affecting subject-specific levels)
    - Credit rewards
    - Custom achievements
    - Optional partial credit for complex answers
  - Assignment features:
    - Due dates
    - Required completion order
    - Multiple attempts settings
    - Time limits
    - Prerequisite quests
    - Optional minimum player level requirements

- Assignment Management:
  - Assign quests to individual players or groups
  - Track completion status
  - Review workflow:
    - Manual verification for free-form answers
    - Partial credit assignment
    - Feedback provision
    - Bulk approval options
  - Progress monitoring dashboard
  - Performance analytics

- Content Marketplace:
  - Browse public subjects and quests
  - Search and filter options
  - Content discovery features:
    - Featured content rotation (weekly/monthly highlights)
    - Trending content section
    - Categories and tags system
    - Age-appropriate filters
    - Difficulty-based filtering
    - Subject area classification
  - Rating and review system
  - Creator profiles and reputation
  - Content sharing between creators
  - Download and customize shared content
  - All shared content must be free

## Technical Architecture

### Smart Contracts (Canisters)
1. **Backend Canister**
   - User management:
     - Profile management
     - Progress tracking
     - Inventory management
   - Quest management:
     - Quest generation
     - Quest validation
     - Progress tracking
     - Reward distribution
   - Store operations:
     - Item management
     - Purchase processing
     - Inventory updates
   - Custom content:
     - Subject/Quest creation and management
     - Assignment distribution
     - Progress tracking
     - Creator permissions management
     - Content visibility control
   - Marketplace features:
     - Content discovery
     - Rating and review system
     - Content sharing mechanics
     - Creator reputation tracking
   - Social features (Future):
     - Leaderboard management
     - Chat system
     - Friend system

2. **Frontend Canister**
   - Internet Identity integration
   - Asset serving
   - Mobile-first responsive UI
   - Client-side caching
   - PWA implementation
   - Offline capabilities

### Frontend
- Mobile-first responsive design:
  - Touch-optimized interface
  - Swipe gestures for navigation
  - Portrait and landscape support
  - Offline capability for active quests
  - Progressive Web App (PWA) features
  - Adaptive UI for different screen sizes
  - Touch-friendly input methods for math/equations
  - Mobile-optimized animations
  - Battery-conscious background processes
- Responsive web interface for desktop
- Cartoonish visual style
- Interactive animations
- Sound effects and feedback
- Accessibility features:
  - Screen reader support
  - High contrast mode
  - Configurable text size
  - Touch target sizing
  - Motion reduction option

### Data Models

#### UserIdentity
```motoko
type UserIdentity = {
  principal: Principal;
  deviceList: [DeviceData];
  activeDevices: [Text];
  lastLogin: Time;
  createdAt: Time;
};
```

#### DeviceData
```motoko
type DeviceData = {
  deviceId: Text;
  alias: Text;
  lastActive: Time;
  deviceType: DeviceType;
};
```

#### UserProfile
```motoko
type UserProfile = {
  id: Text;
  principal: Principal;
  displayName: Text;
  subjectProgress: [(Text, SubjectProgress)];  // Keyed by subject ID, includes root
  inventory: [Item];
  achievements: [Achievement];
  preferences: UserPreferences;
};
```

#### UserPreferences
```motoko
type UserPreferences = {
  theme: Theme;
  soundEnabled: Bool;
  musicEnabled: Bool;
  notificationsEnabled: Bool;
  motionReduced: Bool;
  fontSize: FontSize;
  highContrast: Bool;
  deviceOptimizations: DeviceOptimizations;
};
```

#### SubjectDefinition
```motoko
type SubjectDefinition = {
  id: Text;
  name: Text;
  description: Text;
  parentId: Text;  // All subjects have a parent, root has special ID
  subjectType: {
    #Root;         // The Quizzy game root
    #Core;         // System-defined core subjects
    #System;       // System-defined sub-subjects
    #Custom;       // User-created subjects
  };
  childSubjects: [Text];
  prerequisites: [Text];
  visibility: Visibility;
  currencies: [Currency];  // Empty for non-custom subjects, Credits for root
  xpMultiplier: Float;  // for contribution to parent subject
};
```

#### Currency
```motoko
type Currency = {
  id: Text;
  name: Text;
  description: Text;
  creatorId: Text;
  subjectId: Text;
  created: Time;
  icon: ?Text;  // Optional icon/emoji for the currency
};
```

#### SubjectProgress
```motoko
type SubjectProgress = {
  subject: Text;
  level: Nat;
  xp: Nat;
  currency: Nat;
  questsCompleted: Nat;
  achievements: [Achievement];
  childProgress: [(Text, SubjectProgress)];  // Progress in sub-subjects
  aggregatedXP: Nat;  // Including XP from sub-subjects
  aggregatedLevel: Nat;  // Level considering sub-subjects
};
```

#### Group
```motoko
type Group = {
  id: Text;
  name: Text;
  description: Text;
  creatorPrincipal: Principal;
  members: [Principal];
  validUntil: ?Time;
  isArchived: Bool;
  created: Time;
  lastModified: Time;
};
```

#### AccessControl
```motoko
type AccessControl = {
  individual: [Principal];
  groups: [Text];  // Group IDs
  accessLevel: AccessLevel;
  validFrom: ?Time;
  validUntil: ?Time;
  inheritedFrom: ?Text;  // Parent subject ID if inherited
};
```

#### AccessLevel = {
  #ViewOnly;
  #Attempt;
  #Submit;
  #Review;
  #Manage;
};

#### CustomSubject
```motoko
type CustomSubject = {
  id: Text;
  creatorId: Text;
  parentId: Text;
  name: Text;
  description: Text;
  visibility: {
    #Private: AccessControl;
    #Public;
  };
  customAchievements: [CustomAchievement];
  inheritedProperties: [InheritedProperty];
  xpMultiplier: Float;
  currencyMultiplier: Float;
};
```

#### InheritedProperty
```motoko
type InheritedProperty = {
  propertyType: PropertyType;
  inheritFromParent: Bool;
  customValue: ?PropertyValue;
};
```

#### Quest
```motoko
type Quest = {
  id: Text;
  subject: Text;
  difficulty: Nat;
  levelRequired: Nat;
  xpReward: Nat;
  creditReward: Nat;
  subjectCurrencyReward: Nat;
  timeLimit: ?Nat;
  questionType: QuestionType;
  content: QuestContent;
};
```

#### ContentCreator
```motoko
type ContentCreator = {
  id: Text;
  principal: Principal;
  displayName: Text;
  createdSubjects: [CustomSubject];
  createdQuests: [CustomQuest];
  managedGroups: [Group];
};
```

#### CustomQuest
```motoko
type CustomQuest = {
  id: Text;
  subjectId: Text;
  creatorId: Text;
  title: Text;
  description: Text;
  questionType: CustomQuestionType;
  content: CustomQuestContent;
  answers: [Answer];
  dueDate: ?Time;
  timeLimit: ?Nat;
  xpReward: Nat;
  currencyRewards: [(Text, Nat)];  // (currencyId, amount)
  prerequisites: [Text];
  assignedPlayers: [Text];
  maxAttempts: ?Nat;
  minPlayerLevel: ?Nat;
  requiresVerification: Bool;
  allowPartialCredit: Bool;
  visibility: Visibility;
  rating: ?Rating;
  reviews: [Review];
  tags: [Text];
  category: Category;
  ageRange: AgeRange;
  featured: ?FeaturedContent;
};
```

#### FeaturedContent
```motoko
type FeaturedContent = {
  startDate: Time;
  endDate: Time;
  featuredReason: Text;
  curatorNotes: ?Text;
};
```

#### Rating
```motoko
type Rating = {
  averageScore: Float;
  totalRatings: Nat;
  reviews: [Review];
};
```

#### Review
```motoko
type Review = {
  creatorId: Text;
  rating: Nat;
  comment: Text;
  timestamp: Time;
};
```

## Implementation Phases

### Phase 1: Core Mathematics
- Internet Identity integration
- Basic user system
- Mathematics quest generation
- Core gameplay loop
- XP and leveling system
- Mobile-first UI implementation

### Phase 2: Enhanced Features
- Store implementation
- Items and power-ups
- Additional subjects
- Achievement system

### Phase 2.5: Custom Content Creation
- Content creator role implementation
- Custom subject creation
- Custom quest creation and assignment
- Progress tracking dashboard
- Assignment management system
- Manual verification workflow
- Partial credit system

### Phase 2.75: Content Marketplace
- Public content sharing
- Creator profiles
- Rating and review system
- Content discovery features
- Content customization tools

### Phase 3: Social Features
- Leaderboards
- Chat system
- Friend system
- Competitive elements

### Achievement System
- Achievement Types:
  - Milestone achievements (complete X quests)
  - Mastery achievements (reach level Y)
  - Speed achievements (complete within time Z)
  - Streak achievements (daily/weekly participation)
  - Collection achievements (complete all subjects in a branch)
- Achievement Propagation:
  - Individual subject achievements
  - Branch completion achievements
    - Example: "Geometry Master" for completing all geometry sub-subjects
  - Core subject mastery
    - Example: "Mathematics Guru" for mastering all math subjects
  - Root achievements
    - "Renaissance Scholar" for achieving in multiple core subjects
    - "Grand Master" for reaching high levels in everything
- Achievement Rewards:
  - XP bonuses
  - Currency rewards (both global and subject-specific)
  - Special items or power-ups
  - Cosmetic rewards
  - Title unlocks

### Example Subject Tree Structure
```
Quizzy (Root)
│── Credits as currency
│── Global XP and Level
│
├── Mathematics
│   │── Math Points as currency
│   │
│   ├── Arithmetic
│   │   ├── Basic Operations
│   │   ├── Fractions & Decimals
│   │   └── Number Theory
│   │
│   ├── Algebra
│   │   ├── Basic Algebra
│   │   ├── Advanced Equations
│   │   └── Functions
│   │
│   └── Geometry
│       ├── Basic Shapes
│       ├── Advanced Geometry
│       └── Custom: "My Geometry Homework" (Private)
│
├── Physics
│   │── Physics Points as currency
│   │
│   ├── Mechanics
│   │   ├── Forces
│   │   └── Motion
│   │
│   └── Custom: "Class 10A Physics" (Shared)
│
└── Custom: "Summer Learning Program"
    │── Program Points as currency
    │
    ├── Custom: "Week 1 Materials"
    └── Custom: "Week 2 Materials"
``` 