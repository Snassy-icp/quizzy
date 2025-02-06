import React from 'react';
import { getRequiredXP, calculateQuestXP } from './xpCalculator';

const Help: React.FC = () => {
  // Calculate XP table data
  const generateXPTable = () => {
    const levels = Array.from({ length: 20 }, (_, i) => i + 1);
    return levels.map(level => {
      const totalXP = getRequiredXP(level);
      const previousXP = getRequiredXP(level - 1);
      const levelXP = totalXP - previousXP;
      const questXP = calculateQuestXP(level);
      const questsNeeded = Math.ceil(levelXP / questXP);

      return {
        level,
        totalXP,
        levelXP,
        questXP,
        questsNeeded,
      };
    });
  };

  const xpTableData = generateXPTable();

  return (
    <div className="help-container">
      <h1>Quizzy Help</h1>
      
      <section className="help-section">
        <h2>Getting Started</h2>
        <p>Welcome to Quizzy! This educational game helps you learn and progress through various subjects while earning XP and achievements.</p>
      </section>

      <section className="help-section">
        <h2>How to Play</h2>
        <ol>
          <li>Select a subject you want to practice</li>
          <li>Choose your difficulty level</li>
          <li>Answer questions to earn XP and credits</li>
          <li>Level up to unlock harder challenges</li>
          <li>Collect achievements and items along the way</li>
        </ol>
      </section>

      <section className="help-section">
        <h2>XP and Leveling System</h2>
        <p>Your progress is measured through experience points (XP) and levels. Each level requires more XP than the last, 
           but higher-level quests also give more XP rewards.</p>
        
        <div className="xp-table-container">
          <h3>Level Progression Table</h3>
          <table className="xp-table">
            <thead>
              <tr>
                <th>Level</th>
                <th>Total XP</th>
                <th>XP for Level</th>
                <th>Quest XP</th>
                <th>Quests Needed</th>
              </tr>
            </thead>
            <tbody>
              {xpTableData.map(({ level, totalXP, levelXP, questXP, questsNeeded }) => (
                <tr key={level}>
                  <td>{level}</td>
                  <td>{totalXP.toLocaleString()}</td>
                  <td>{levelXP.toLocaleString()}</td>
                  <td>{questXP.toLocaleString()}</td>
                  <td>{questsNeeded}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="help-section">
        <h2>Subjects</h2>
        <p>Quizzy offers various subjects to learn and master:</p>
        <ul>
          <li><strong>Mathematics:</strong> From basic arithmetic to advanced algebra</li>
          <li><strong>More subjects coming soon!</strong></li>
        </ul>
      </section>

      <section className="help-section">
        <h2>Tips</h2>
        <ul>
          <li>Start with lower difficulty levels to build confidence</li>
          <li>Practice regularly to maintain your progress</li>
          <li>Challenge yourself with harder questions as you level up</li>
          <li>Pay attention to explanations when you make mistakes</li>
        </ul>
      </section>
    </div>
  );
};

export default Help; 