// Constants matching backend implementation
const BASE_XP = 100;
const LEVEL_GROWTH_FACTOR = 1.2;
const BASE_QUEST_XP = 10;
const QUEST_XP_GROWTH = 1.15;
const BASE_CREDITS = 5;
const CREDIT_GROWTH = 1.1;  // 10% increase per level

export const getRequiredXP = (level: number): number => {
    if (level === 1) return 0;
    if (level === 2) return BASE_XP;
    
    let total = BASE_XP;
    let currentLevelXP = BASE_XP;
    
    for (let i = 2; i < level; i++) {
        currentLevelXP *= LEVEL_GROWTH_FACTOR;
        total += Math.floor(currentLevelXP);
    }
    
    return total;
};

export const getXpThreshold = (level: number): number => {
    return getRequiredXP(level + 1) - getRequiredXP(level);
};

export const getCurrentLevelXP = (totalXP: number, level: number): number => {
    return totalXP - getRequiredXP(level);
};

export const calculateQuestXP = (difficulty: number): number => {
    if (difficulty === 1) return BASE_QUEST_XP;
    
    let xp = BASE_QUEST_XP;
    for (let i = 1; i < difficulty; i++) {
        xp *= QUEST_XP_GROWTH;
    }
    
    return Math.floor(xp);
};

export const calculateQuestCredits = (difficulty: number): number => {
    if (difficulty === 1) return BASE_CREDITS;
    
    let credits = BASE_CREDITS;
    for (let i = 1; i < difficulty; i++) {
        credits *= CREDIT_GROWTH;
    }
    
    return Math.floor(credits);
}; 