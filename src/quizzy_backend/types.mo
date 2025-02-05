import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    public type UserProfile = {
        principal: Principal;
        displayName: Text;
        subjectProgress: [(Text, SubjectProgress)];
        inventory: [Item];
        achievements: [Achievement];
        preferences: UserPreferences;
    };

    public type SubjectProgress = {
        subject: Nat;
        level: Nat;
        xp: Nat;
        credits: Nat;
        questsCompleted: Nat;
        achievements: [Achievement];
        childProgress: [(Nat, SubjectProgress)];
        aggregatedXP: Nat;
        aggregatedLevel: Nat;
        completedQuests: [Nat];  // Array of completed quest IDs
    };

    public type Achievement = {
        id: Text;
        name: Text;
        description: Text;
        unlocked: Bool;
        unlockedAt: ?Time.Time;
        progress: Nat;  // For tracking partial progress
        maxProgress: Nat;
    };

    public type UserPreferences = {
        theme: Theme;
        soundEnabled: Bool;
        musicEnabled: Bool;
        notificationsEnabled: Bool;
        motionReduced: Bool;
        fontSize: FontSize;
        highContrast: Bool;
    };

    public type Theme = {
        #Light;
        #Dark;
        #System;
    };

    public type FontSize = {
        #Small;
        #Medium;
        #Large;
        #ExtraLarge;
    };

    public type Item = {
        id: Text;
        name: Text;
        description: Text;
        itemType: ItemType;
        acquired: Time.Time;
        expiresAt: ?Time.Time;
    };

    public type ItemType = {
        #PowerUp;
        #Cosmetic;
        #Achievement;
    };

    public type SubjectType = {
        #Root;         // The Quizzy game root
        #Core;         // System-defined core subjects
        #System;       // System-defined sub-subjects
        #Custom;       // User-created subjects
    };

    public type Subject = {
        id: Nat;
        name: Text;
        description: Text;
        parentId: Nat;
        subjectType: SubjectType;
        childSubjects: [Nat];
        prerequisites: [Nat];
        xpMultiplier: Float;
    };

    // Basic quest types for core mathematics
    public type Quest = {
        id: Nat;
        subject: Nat;
        difficulty: Nat;  // 1-10
        levelRequired: Nat;
        xpReward: Nat;
        creditReward: Nat;  // Only for system quests
        timeLimit: ?Nat;  // In seconds
        questionType: QuestionType;
        content: QuestContent;
    };

    public type QuestionType = {
        #MultipleChoice;
        #Numeric;
        #Text;
    };

    public type QuestContent = {
        question: Text;
        options: ?[Text];  // For multiple choice
        correctAnswer: Text;  // For numeric/text, or index for multiple choice
        explanation: ?Text;  // Shown after attempt
    };
}; 