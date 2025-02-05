import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    public type UserProfile = {
        id: Text;
        principal: Principal;
        displayName: Text;
        subjectProgress: [(Text, SubjectProgress)];
        inventory: [Item];
        achievements: [Achievement];
        preferences: UserPreferences;
    };

    public type SubjectProgress = {
        subject: Text;
        level: Nat;
        xp: Nat;
        questsCompleted: Nat;
        achievements: [Achievement];
        childProgress: [(Text, SubjectProgress)];
        aggregatedXP: Nat;
        aggregatedLevel: Nat;
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
        id: Text;
        name: Text;
        description: Text;
        parentId: Text;
        subjectType: SubjectType;
        childSubjects: [Text];
        prerequisites: [Text];
        xpMultiplier: Float;
    };

    // Basic quest types for core mathematics
    public type Quest = {
        id: Text;
        subject: Text;
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