# Quizzy - Educational Game Platform Specification

## Core Concepts

### Player Profile
- Each player has:
  - A unique identifier and display name
  - A master level and master XP
  - Subject-specific levels and XP
  - Credits (in-game currency)
  - Inventory of purchased items
  - Achievement tracking

### Subjects and Progression
- Modular subject system allowing easy addition of new subjects
- Initial focus on Mathematics, expandable to Physics, Geography, Biology, etc.
- Each subject has:
  - Independent level progression
  - Subject-specific XP tracking
  - Difficulty tiers (1-10 initially)
  - Achievement tree
  - Unlockable content based on level

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
  - Can assign quests to specific players
  - Can set XP and credit rewards
  - Can track assigned players' progress
  - Can create custom achievement milestones

### Custom Content Creation
- Private Subject Creation:
  - Custom subject name and description
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
1. **User Management Canister**
   - Profile management
   - Authentication
   - Progress tracking
   - Inventory management

2. **Quest Management Canister**
   - Quest generation
   - Quest validation
   - Progress tracking
   - Reward distribution

3. **Store Canister**
   - Item management
   - Purchase processing
   - Inventory updates

4. **Social Canister** (Future)
   - Leaderboard management
   - Chat system
   - Friend system

5. **Custom Content Canister**
   - Subject/Quest creation and management
   - Assignment distribution
   - Progress tracking
   - Creator permissions management
   - Content visibility control

6. **Marketplace Canister**
   - Content discovery
   - Rating and review system
   - Content sharing mechanics
   - Creator reputation tracking

### Frontend
- Modern, responsive web interface
- Cartoonish visual style
- Interactive animations
- Sound effects and feedback
- Mobile-friendly design

### Data Models

#### User Profile
```motoko
type UserProfile = {
  id: Text;
  displayName: Text;
  masterLevel: Nat;
  masterXP: Nat;
  credits: Nat;
  subjectProgress: [(Text, SubjectProgress)];
  inventory: [Item];
  achievements: [Achievement];
};
```

#### Subject Progress
```motoko
type SubjectProgress = {
  subject: Text;
  level: Nat;
  xp: Nat;
  questsCompleted: Nat;
  achievements: [Achievement];
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
  timeLimit: ?Nat;
  questionType: QuestionType;
  content: QuestContent;
};
```

#### ContentCreator
```motoko
type ContentCreator = {
  id: Text;
  displayName: Text;
  assignedPlayers: [Text];
  createdSubjects: [CustomSubject];
  createdQuests: [CustomQuest];
};
```

#### CustomSubject
```motoko
type CustomSubject = {
  id: Text;
  creatorId: Text;
  name: Text;
  description: Text;
  assignedPlayers: [Text];
  visibility: Visibility;
  customAchievements: [CustomAchievement];
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
  creditReward: Nat;
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
- Basic user system
- Mathematics quest generation
- Core gameplay loop
- XP and leveling system

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