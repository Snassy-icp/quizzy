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
    private stable var stableUsers : [(Principal, Types.UserProfile)] = [];
    private stable var stableSubjects : [(Text, Types.Subject)] = [];
    private stable var stableQuests : [(Nat, Types.Quest)] = [];

    // In-memory storage
    private let users = HashMap.HashMap<Principal, Types.UserProfile>(10, Principal.equal, Principal.hash);
    private let subjects = HashMap.HashMap<Text, Types.Subject>(10, Text.equal, Text.hash);
    private let quests = HashMap.HashMap<Nat, Types.Quest>(10, Nat.equal, Hash.hash);
    private let usedNames = HashMap.HashMap<Text, Bool>(10, Text.equal, Text.hash);

    // Initialize root subject if it doesn't exist
    private func initRootSubject() {
        switch (subjects.get("root")) {
            case (?_) { return; }; // Root already exists
            case null {
                let rootSubject : Types.Subject = {
                    id = "root";
                    name = "Quizzy";
                    description = "The root of all knowledge";
                    parentId = "root"; // Self-referential for root
                    subjectType = #Root;
                    childSubjects = [];
                    prerequisites = [];
                    xpMultiplier = 1.0;
                };
                subjects.put("root", rootSubject);
            };
        };
    };

    // Initialize core subjects if they don't exist
    private func initCoreSubjects() {
        switch (subjects.get("math")) {
            case (?_) { return; }; // Math subject already exists
            case null {
                let mathSubject : Types.Subject = {
                    id = "math";
                    name = "Mathematics";
                    description = "The language of the universe";
                    parentId = "root";
                    subjectType = #Core;
                    childSubjects = [];
                    prerequisites = [];
                    xpMultiplier = 1.0;
                };
                subjects.put("math", mathSubject);
            };
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

    // Quest Generation for Mathematics
    public func generateMathQuest(difficulty : Nat) : async Types.Quest {
        let questId = nextQuestId;
        nextQuestId += 1;

        // Simple addition for now, we'll expand this
        let (num1, num2) = generateNumbers(difficulty);
        let answer = Nat.toText(num1 + num2);
        
        let quest : Types.Quest = {
            id = questId;
            subject = "math";
            difficulty = difficulty;
            levelRequired = 1;
            xpReward = difficulty * 10;
            creditReward = difficulty * 5;
            timeLimit = ?60;  // 60 seconds
            questionType = #Numeric;
            content = {
                question = "What is " # Nat.toText(num1) # " + " # Nat.toText(num2) # "?";
                options = null;
                correctAnswer = answer;
                explanation = ?"Addition is combining numbers together";
            };
        };

        quests.put(questId, quest);
        return quest;
    };

    // Helper function to generate numbers based on difficulty
    private func generateNumbers(difficulty : Nat) : (Nat, Nat) {
        let base = switch difficulty {
            case 1 { 10 };
            case 2 { 100 };
            case _ { 1000 };
        };
        
        // For now, just use the Time as a simple random seed
        let time = Time.now();
        let num1 = Int.abs(time) % base;
        let num2 = Int.abs(time / 1_000_000) % base;
        
        (num1, num2)
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
        // For now, just update the math subject progress
        let mathProgress = switch (Array.find<(Text, Types.SubjectProgress)>(
            user.subjectProgress, 
            func((id, _)) { id == "math" }
        )) {
            case null {
                // Create new progress
                ("math", {
                    subject = "math";
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
            if (id != "math") {
                newProgress.add((id, prog));
            };
        };
        newProgress.add(mathProgress);

        {
            user with
            subjectProgress = Buffer.toArray(newProgress);
        }
    };

    // Helper to calculate level based on XP
    private func calculateLevel(xp : Nat) : Nat {
        // Simple level calculation for now
        // Level 1: 0-100 XP
        // Level 2: 101-250 XP
        // Level 3: 251-500 XP
        // etc.
        if (xp <= 100) return 1;
        if (xp <= 250) return 2;
        if (xp <= 500) return 3;
        if (xp <= 1000) return 4;
        return 5;  // Cap at level 5 for now
    };
};
