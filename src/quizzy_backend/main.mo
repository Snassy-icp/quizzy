import Types "types";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";

actor Quizzy {
    // State
    private stable var nextQuestId : Nat = 0;
    private stable var nextSubjectId : Nat = 0;
    private stable var nextAchievementId : Nat = 0;
    private stable var nextItemId : Nat = 0;
    private stable var stableUsers : [(Principal, Types.UserProfile)] = [];
    private stable var stableSubjects : [(Nat, Types.Subject)] = [];
    private stable var stableQuests : [(Nat, Types.Quest)] = [];

    // In-memory storage
    private let users = HashMap.HashMap<Principal, Types.UserProfile>(10, Principal.equal, Principal.hash);
    private let subjects = HashMap.HashMap<Nat, Types.Subject>(10, Nat.equal, Hash.hash);
    private let quests = HashMap.HashMap<Nat, Types.Quest>(10, Nat.equal, Hash.hash);
    private let usedNames = HashMap.HashMap<Text, Bool>(10, Text.equal, Text.hash);

    // Initialize root subject if it doesn't exist
    private func initRootSubject() {
        switch (Array.find<(Nat, Types.Subject)>(
            Iter.toArray(subjects.entries()),
            func((_, subject)) { subject.subjectType == #Root }
        )) {
            case (?_) { return; }; // Root already exists
            case null {
                let rootId = nextSubjectId;
                nextSubjectId += 1;
                let rootSubject : Types.Subject = {
                    id = rootId;
                    name = "Quizzy";
                    description = "The root of all knowledge";
                    parentId = rootId; // Self-referential for root
                    subjectType = #Root;
                    childSubjects = [];
                    prerequisites = [];
                    xpMultiplier = 1.0;
                };
                subjects.put(rootId, rootSubject);
            };
        };
    };

    // Initialize core subjects if they don't exist
    private func initCoreSubjects() {
        // First find the root subject
        let rootSubject = Array.find<(Nat, Types.Subject)>(
            Iter.toArray(subjects.entries()),
            func((_, subject)) { subject.subjectType == #Root }
        );
        
        switch (rootSubject) {
            case (?(id, root)) {
                // Check if math subject exists
                switch (Array.find<(Nat, Types.Subject)>(
                    Iter.toArray(subjects.entries()),
                    func((_, subject)) { 
                        subject.subjectType == #Core and subject.name == "Mathematics"
                    }
                )) {
                    case (?_) { return; }; // Math subject already exists
                    case null {
                        let mathId = nextSubjectId;
                        nextSubjectId += 1;
                        let mathSubject : Types.Subject = {
                            id = mathId;
                            name = "Mathematics";
                            description = "The language of the universe";
                            parentId = id;
                            subjectType = #Core;
                            childSubjects = [];
                            prerequisites = [];
                            xpMultiplier = 1.0;
                        };
                        subjects.put(mathId, mathSubject);
                        
                        // Update root subject's childSubjects
                        switch (subjects.get(id)) {
                            case (?root) {
                                subjects.put(id, {
                                    root with
                                    childSubjects = Array.append(root.childSubjects, [mathId]);
                                });
                            };
                            case null { };
                        };
                    };
                };
            };
            case null { };
        };
    };

    // System functions
    system func preupgrade() {
        // Convert HashMaps to stable arrays before upgrade
        stableUsers := Iter.toArray(users.entries());
        stableSubjects := Iter.toArray(subjects.entries());
        stableQuests := Iter.toArray(quests.entries());
    };

    system func postupgrade() {
        // Restore HashMaps from stable storage
        for ((principal, profile) in stableUsers.vals()) {
            users.put(principal, profile);
            // Reconstruct usedNames from user profiles
            usedNames.put(profile.displayName, true);
        };
        
        // Restore subjects and quests
        for ((id, subject) in stableSubjects.vals()) {
            subjects.put(id, subject);
        };
        for ((id, quest) in stableQuests.vals()) {
            quests.put(id, quest);
        };
        
        // Clear stable storage to free memory
        stableUsers := [];
        stableSubjects := [];
        stableQuests := [];
        
        // Initialize subjects only if they don't exist
        initRootSubject();
        initCoreSubjects();
    };

    // User Management
    public shared(msg) func createProfile(displayName : Text) : async Types.UserProfile {
        let caller = msg.caller;
        
        switch (users.get(caller)) {
            case (?existing) {
                throw Error.reject("Profile already exists");
            };
            case null {
                // Check if name is taken
                switch (usedNames.get(displayName)) {
                    case (?taken) {
                        if (taken) {
                            throw Error.reject("Display name is already taken");
                        };
                    };
                    case null { };
                };

                let newProfile : Types.UserProfile = {
                    principal = caller;
                    displayName = displayName;
                    subjectProgress = [];
                    inventory = [];
                    achievements = [];
                    preferences = {
                        theme = #System;
                        soundEnabled = true;
                        musicEnabled = true;
                        notificationsEnabled = true;
                        motionReduced = false;
                        fontSize = #Medium;
                        highContrast = false;
                    };
                };

                users.put(caller, newProfile);
                usedNames.put(displayName, true);
                return newProfile;
            };
        };
    };

    public shared query(msg) func getProfile() : async ?Types.UserProfile {
        users.get(msg.caller)
    };

    // Check if a display name is available
    public shared query func isDisplayNameAvailable(name : Text) : async Bool {
        switch (usedNames.get(name)) {
            case (?taken) { return not taken; };
            case null { return true; };
        };
    };

    // Change display name
    public shared(msg) func changeDisplayName(newName : Text) : async Types.UserProfile {
        // Check if name is taken
        switch (usedNames.get(newName)) {
            case (?taken) {
                if (taken) {
                    throw Error.reject("Display name is already taken");
                };
            };
            case null { };
        };
        
        // Get current user profile
        switch (users.get(msg.caller)) {
            case (?user) {
                // Remove old name from used names
                usedNames.delete(user.displayName);
                
                // Update with new name
                let updatedProfile : Types.UserProfile = {
                    user with
                    displayName = newName;
                };
                
                users.put(msg.caller, updatedProfile);
                usedNames.put(newName, true);
                return updatedProfile;
            };
            case null {
                throw Error.reject("User profile not found");
            };
        };
    };

    // Calculate quest credit reward based on difficulty
    private func calculateQuestCredits(difficulty : Nat) : Nat {
        let baseCredits : Nat = 5;  // Base credits for level 1 quests
        let creditGrowth : Float = 1.1;  // 10% more credits for each difficulty level
        
        if (difficulty == 1) return baseCredits;
        
        var credits : Float = Float.fromInt(baseCredits);
        var i : Nat = 1;
        while (i < difficulty) {
            credits := credits * creditGrowth;
            i += 1;
        };
        
        Int.abs(Float.toInt(credits))
    };

    // Quest Generation for Mathematics
    public func generateMathQuest(difficulty : Nat) : async Types.Quest {
        let questId = nextQuestId;
        nextQuestId += 1;

        // Find math subject ID
        let mathSubject = Array.find<(Nat, Types.Subject)>(
            Iter.toArray(subjects.entries()),
            func((_, subject)) { 
                subject.subjectType == #Core and subject.name == "Mathematics"
            }
        );
        
        switch (mathSubject) {
            case (?(id, subject)) {
                // Calculate rewards based on difficulty
                let xpReward = calculateQuestXP(difficulty);
                let creditReward = calculateQuestCredits(difficulty);

                // Generate quest based on difficulty level
                let (question, answer, explanation) = switch difficulty {
                    // Level 1: Simple addition and subtraction
                    case 1 {
                        let (num1, num2) = generateNumbers(difficulty);
                        let isAddition = Int.abs(Time.now()) % 2 == 0;
                        if (isAddition) {
                            (
                                "What is " # Nat.toText(num1) # " + " # Nat.toText(num2) # "?",
                                Nat.toText(num1 + num2),
                                ?"Addition is combining numbers together"
                            )
                        } else {
                            // Ensure num1 is larger for subtraction
                            let (larger, smaller) = if (num1 >= num2) { (num1, num2) } else { (num2, num1) };
                            (
                                "What is " # Nat.toText(larger) # " - " # Nat.toText(smaller) # "?",
                                Nat.toText(larger - smaller),
                                ?"Subtraction is finding the difference between numbers"
                            )
                        }
                    };
                    // Level 2: Multiplication and division
                    case 2 {
                        let (num1, num2) = generateNumbers(1); // Use smaller numbers for multiplication
                        let isMultiplication = Int.abs(Time.now()) % 2 == 0;
                        if (isMultiplication) {
                            (
                                "What is " # Nat.toText(num1) # " × " # Nat.toText(num2) # "?",
                                Nat.toText(num1 * num2),
                                ?"Multiplication is repeated addition"
                            )
                        } else {
                            // Ensure division results in whole number
                            let product = num1 * num2;
                            (
                                "What is " # Nat.toText(product) # " ÷ " # Nat.toText(num1) # "?",
                                Nat.toText(num2),
                                ?"Division is finding how many times one number goes into another"
                            )
                        }
                    };
                    // Level 3-4: Coming soon
                    case 3 { generateFractionQuest() };
                    case 4 { generateDecimalQuest() };
                    // Level 5-6: Coming soon
                    case 5 { generateBasicAlgebraQuest() };
                    case 6 { generateAdvancedAlgebraQuest() };
                    // Default to level 1
                    case _ { generateFallbackQuest() };
                };
                
                let quest : Types.Quest = {
                    id = questId;
                    subject = id;
                    difficulty = difficulty;
                    levelRequired = difficulty;
                    xpReward = xpReward;
                    creditReward = creditReward;
                    timeLimit = ?60;  // 60 seconds
                    questionType = #Numeric;
                    content = {
                        question = question;
                        options = null;
                        correctAnswer = answer;
                        explanation = explanation;
                    };
                };

                quests.put(questId, quest);
                return quest;
            };
            case null {
                throw Error.reject("Math subject not found");
            };
        };
    };

    // Helper function to generate numbers based on difficulty
    private func generateNumbers(difficulty : Nat) : (Nat, Nat) {
        let base = switch difficulty {
            case 1 { 10 };
            case 2 { 100 };
            case _ { 1000 };
        };
        
        // Use time-based randomization with some extra entropy
        let time = Time.now();
        let seed1 = Int.abs(time) + Int.abs(nextQuestId);
        let seed2 = Int.abs(time / 1_000_000) + Int.abs(nextQuestId * 2);
        
        let num1 = seed1 % base;
        let num2 = seed2 % base;
        
        (num1, num2)
    };

    // Placeholder functions for higher difficulty levels
    private func generateFractionQuest() : (Text, Text, ?Text) {
        ("Coming soon: Fraction quest", "0", ?"This feature is under development")
    };

    private func generateDecimalQuest() : (Text, Text, ?Text) {
        ("Coming soon: Decimal quest", "0", ?"This feature is under development")
    };

    private func generateBasicAlgebraQuest() : (Text, Text, ?Text) {
        ("Coming soon: Basic Algebra quest", "0", ?"This feature is under development")
    };

    private func generateAdvancedAlgebraQuest() : (Text, Text, ?Text) {
        ("Coming soon: Advanced Algebra quest", "0", ?"This feature is under development")
    };

    private func generateFallbackQuest() : (Text, Text, ?Text) {
        let (num1, num2) = generateNumbers(1);
        (
            "What is " # Nat.toText(num1) # " + " # Nat.toText(num2) # "?",
            Nat.toText(num1 + num2),
            ?"Addition is combining numbers together"
        )
    };

    // Quest Submission
    public shared(msg) func submitAnswer(questId : Nat, answer : Text) : async Bool {
        switch (quests.get(questId)) {
            case null { 
                throw Error.reject("Quest not found");
            };
            case (?quest) {
                let correct = quest.content.correctAnswer == answer;
                
                if (correct) {
                    // Update user progress
                    switch (users.get(msg.caller)) {
                        case null { 
                            throw Error.reject("User not found");
                        };
                        case (?user) {
                            // Check if user has already completed this quest
                            let mathProgress = Array.find<(Text, Types.SubjectProgress)>(
                                user.subjectProgress,
                                func((id, _)) { id == "math" }
                            );
                            
                            switch (mathProgress) {
                                case (?(_, progress)) {
                                    // Check if quest is already completed
                                    let alreadyCompleted = Array.find<Nat>(
                                        progress.completedQuests,
                                        func(id) { id == questId }
                                    );
                                    
                                    switch (alreadyCompleted) {
                                        case (?_) {
                                            // Quest already completed, return true but don't update progress
                                            return true;
                                        };
                                        case null {
                                            // First time completing this quest, update progress
                                            let updatedUser = updateProgress(user, quest);
                                            users.put(msg.caller, updatedUser);
                                        };
                                    };
                                };
                                case null {
                                    // First quest in this subject, update progress
                                    let updatedUser = updateProgress(user, quest);
                                    users.put(msg.caller, updatedUser);
                                };
                            };
                        };
                    };
                };
                
                return correct;
            };
        };
    };

    // Helper to update user progress
    private func updateProgress(user : Types.UserProfile, quest : Types.Quest) : Types.UserProfile {
        // For now, just update the subject progress
        let subjectProgress = switch (Array.find<(Text, Types.SubjectProgress)>(
            user.subjectProgress, 
            func((_, progress)) { progress.subject == quest.subject }
        )) {
            case null {
                // Create new progress
                (Nat.toText(quest.subject), {
                    subject = quest.subject;
                    level = 1;
                    xp = quest.xpReward;
                    credits = quest.creditReward;
                    questsCompleted = 1;
                    achievements = [];
                    childProgress = [];
                    aggregatedXP = quest.xpReward;
                    aggregatedLevel = 1;
                    completedQuests = [quest.id];
                })
            };
            case (?(id, progress)) {
                // Update existing progress
                (id, {
                    subject = progress.subject;
                    level = calculateLevel(progress.xp + quest.xpReward);
                    xp = progress.xp + quest.xpReward;
                    credits = progress.credits + quest.creditReward;
                    questsCompleted = progress.questsCompleted + 1;
                    achievements = progress.achievements;
                    childProgress = progress.childProgress;
                    aggregatedXP = progress.aggregatedXP + quest.xpReward;
                    aggregatedLevel = calculateLevel(progress.aggregatedXP + quest.xpReward);
                    completedQuests = Array.append(progress.completedQuests, [quest.id]);
                })
            };
        };

        let newProgress = Buffer.Buffer<(Text, Types.SubjectProgress)>(1);
        for ((id, prog) in user.subjectProgress.vals()) {
            if (prog.subject != quest.subject) {
                newProgress.add((id, prog));
            };
        };
        newProgress.add(subjectProgress);

        {
            user with
            subjectProgress = Buffer.toArray(newProgress);
        }
    };

    // Helper to calculate level based on XP
    private func calculateLevel(xp : Nat) : Nat {
        // Formula: Each level requires baseXP * (growthFactor ^ (level - 1)) XP
        // baseXP = 100 (XP needed for level 1)
        // growthFactor = 1.2 (20% more XP needed for each level)
        
        if (xp == 0) return 1;
        
        // Binary search to find the level
        var low : Nat = 1;
        var high : Nat = 100; // Maximum level cap
        
        while (low <= high) {
            let mid = low + (high - low) / 2;
            let required = getRequiredXP(mid);
            
            if (required <= xp and (mid == 100 or getRequiredXP(mid + 1) > xp)) {
                return mid;
            } else if (required <= xp) {
                low := mid + 1;
            } else {
                high := mid - 1;
            };
        };
        
        1 // Fallback to level 1
    };

    // Helper to calculate required XP for a level
    private func getRequiredXP(level : Nat) : Nat {
        let baseXP : Nat = 100;  // XP needed for level 1
        let growthFactor : Float = 1.2;  // 20% more XP needed for each level
        
        if (level == 1) return 0;
        if (level == 2) return baseXP;
        
        // Calculate total XP needed: baseXP * sum(growthFactor^(i-1)) for i from 1 to level-1
        var total : Nat = baseXP;  // Start with level 1 requirement
        var currentLevelXP : Float = Float.fromInt(baseXP);
        
        var i : Nat = 2;
        while (i < level) {
            currentLevelXP := currentLevelXP * growthFactor;
            total += Int.abs(Float.toInt(currentLevelXP));
            i += 1;
        };
        
        total
    };

    // Calculate quest XP reward based on difficulty
    private func calculateQuestXP(difficulty : Nat) : Nat {
        let baseQuestXP : Nat = 10;  // Base XP for level 1 quests
        let questXPGrowth : Float = 1.15;  // 15% more XP for each difficulty level
        
        if (difficulty == 1) return baseQuestXP;
        
        var xp : Float = Float.fromInt(baseQuestXP);
        var i : Nat = 1;
        while (i < difficulty) {
            xp := xp * questXPGrowth;
            i += 1;
        };
        
        Int.abs(Float.toInt(xp))
    };

    // Helper to get XP threshold for next level
    private func getNextLevelThreshold(level : Nat) : Nat {
        getRequiredXP(level + 1) - getRequiredXP(level)
    };

    // Helper to get XP threshold for current level
    private func getCurrentLevelThreshold(level : Nat) : Nat {
        getRequiredXP(level)
    };

    // Helper to calculate XP within current level
    private func calculateCurrentLevelXP(totalXP : Nat, level : Nat) : Nat {
        totalXP - getCurrentLevelThreshold(level)
    };

    // Get subject information
    public query func getSubject(subjectId : Nat) : async ?Types.Subject {
        subjects.get(subjectId)
    };

    // Get multiple subjects at once (more efficient for the frontend)
    public query func getSubjects(subjectIds : [Nat]) : async [(Nat, Types.Subject)] {
        let results = Buffer.Buffer<(Nat, Types.Subject)>(subjectIds.size());
        for (id in subjectIds.vals()) {
            switch (subjects.get(id)) {
                case (?subject) {
                    results.add((id, subject));
                };
                case null { };
            };
        };
        Buffer.toArray(results)
    };

    // Helper function to create a new achievement
    private func createAchievement(name: Text, description: Text, maxProgress: Nat) : Types.Achievement {
        let id = nextAchievementId;
        nextAchievementId += 1;
        {
            id = id;
            name = name;
            description = description;
            unlocked = false;
            unlockedAt = null;
            progress = 0;
            maxProgress = maxProgress;
        }
    };

    // Helper function to create a new item
    private func createItem(name: Text, description: Text, itemType: Types.ItemType, expiresAt: ?Time.Time) : Types.Item {
        let id = nextItemId;
        nextItemId += 1;
        {
            id = id;
            name = name;
            description = description;
            itemType = itemType;
            acquired = Time.now();
            expiresAt = expiresAt;
        }
    };
};
