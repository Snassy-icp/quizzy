import React, { useState, useEffect } from 'react';
import { AuthClient } from '@dfinity/auth-client';
import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory, canisterId } from '../../../src/declarations/quizzy_backend';
import type { _SERVICE } from '../../../src/declarations/quizzy_backend/quizzy_backend.did.d.ts';

// Helper function to safely stringify BigInt values
const bigIntReplacer = (_key: string, value: any) => {
  if (typeof value === 'bigint') {
    return Number(value);
  }
  return value;
};

// Helper function to get XP threshold for next level
const getXpThreshold = (currentXp: number): number => {
  if (currentXp <= 100) return 100;
  if (currentXp <= 250) return 250;
  if (currentXp <= 500) return 500;
  if (currentXp <= 1000) return 1000;
  return 1000; // Level 5 cap for now
};

declare global {
  interface Window {
    ENV: {
      QUIZZY_BACKEND_CANISTER_ID: string;
      II_URL: string;
    }
  }
}

const App: React.FC = () => {
  const [authClient, setAuthClient] = useState<AuthClient | null>(null);
  const [actor, setActor] = useState<_SERVICE | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [currentQuest, setCurrentQuest] = useState<any>(null);
  const [answer, setAnswer] = useState('');
  const [feedback, setFeedback] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [newDisplayName, setNewDisplayName] = useState('');
  const [isEditingName, setIsEditingName] = useState(false);
  const [nameAvailabilityMessage, setNameAvailabilityMessage] = useState<string | null>(null);

  // Initialize auth client
  useEffect(() => {
    AuthClient.create().then(async client => {
      setAuthClient(client);
      const isAuth = await client.isAuthenticated();
      setIsAuthenticated(isAuth);
      if (isAuth) {
        initActor(client);
      }
    });
  }, []);

  // Initialize backend actor
  const initActor = async (client: AuthClient) => {
    try {
      const identity = client.getIdentity();
      const agent = new HttpAgent({ 
        identity,
        host: process.env.DFX_NETWORK === "ic" ? "https://ic0.app" : undefined
      });
      
      // Only fetch root key when not on mainnet
      if (process.env.DFX_NETWORK !== "ic") {
        await agent.fetchRootKey();
      }
      
      const canisterIdToUse = window.ENV?.QUIZZY_BACKEND_CANISTER_ID || canisterId;
      console.log('Using canister ID:', canisterIdToUse);
      
      // Create a new actor with the identity
      const newActor = Actor.createActor<_SERVICE>(idlFactory, {
        agent,
        canisterId: canisterIdToUse,
      });
      setActor(newActor);
      
      // Try to get existing profile
      const profile = await newActor.getProfile();
      console.log('Retrieved profile:', JSON.stringify(profile, bigIntReplacer, 2));
      if (profile && profile.length > 0) {
        setProfile(profile[0]);
      }
    } catch (e) {
      console.error('Error in initActor:', e);
      setError(e instanceof Error ? e.message : 'An error occurred during initialization');
    }
  };

  // Login with Internet Identity
  const login = async () => {
    if (authClient) {
      try {
        await authClient.login({
          identityProvider: window.ENV?.II_URL || "https://identity.ic0.app",
          onSuccess: () => {
            setIsAuthenticated(true);
            initActor(authClient);
          },
        });
      } catch (e) {
        console.error('Login error:', e);
        setError(e instanceof Error ? e.message : 'An error occurred during login');
      }
    }
  };

  // Check if display name is available
  const checkNameAvailability = async (name: string) => {
    if (actor && name.trim()) {
      try {
        const isAvailable = await actor.isDisplayNameAvailable(name);
        setNameAvailabilityMessage(isAvailable ? '✓ Name is available' : '✗ Name is already taken');
        return isAvailable;
      } catch (e) {
        console.error('Error checking name availability:', e);
        setNameAvailabilityMessage(null);
        return false;
      }
    }
    setNameAvailabilityMessage(null);
    return false;
  };

  // Create profile if doesn't exist
  const createProfile = async () => {
    if (actor) {
      try {
        if (!newDisplayName.trim()) {
          setError('Please enter a display name');
          return;
        }
        
        console.log('Creating profile with name:', newDisplayName);
        const newProfile = await actor.createProfile(newDisplayName);
        console.log('Profile created (full data):', JSON.stringify(newProfile, bigIntReplacer, 2));
        if (newProfile) {
          setProfile(newProfile);
          setError(null);
          setNewDisplayName('');
          setNameAvailabilityMessage(null);
        }
      } catch (e) {
        console.error('Error creating profile:', e);
        setError(e instanceof Error ? e.message : 'An error occurred while creating profile');
      }
    } else {
      console.error('Actor not initialized');
      setError('System not properly initialized');
    }
  };

  // Change display name
  const changeDisplayName = async () => {
    if (actor && newDisplayName.trim()) {
      try {
        const updatedProfile = await actor.changeDisplayName(newDisplayName);
        setProfile(updatedProfile);
        setIsEditingName(false);
        setNewDisplayName('');
        setNameAvailabilityMessage(null);
        setError(null);
      } catch (e) {
        console.error('Error changing display name:', e);
        setError(e instanceof Error ? e.message : 'An error occurred while changing display name');
      }
    }
  };

  // Generate new math quest
  const generateQuest = async () => {
    if (actor) {
      try {
        const quest = await actor.generateMathQuest(1);
        console.log('Generated quest:', JSON.stringify(quest, bigIntReplacer, 2));
        setCurrentQuest(quest);
        setAnswer('');
        setFeedback('');
        setError(null);
      } catch (e) {
        console.error('Error generating quest:', e);
        setError(e instanceof Error ? e.message : 'An error occurred while generating quest');
      }
    }
  };

  // Submit answer
  const submitAnswer = async () => {
    if (actor && currentQuest) {
      try {
        const result = await actor.submitAnswer(currentQuest.id, answer);
        setFeedback(result ? 'Correct!' : 'Wrong answer, try again!');
        if (result) {
          const updatedProfile = await actor.getProfile();
          if (updatedProfile && updatedProfile.length > 0) {
            setProfile(updatedProfile[0]);
          }
        }
        setError(null);
      } catch (e) {
        console.error('Error submitting answer:', e);
        setError(e instanceof Error ? e.message : 'An error occurred while submitting answer');
      }
    }
  };

  // Add logout function
  const logout = async () => {
    if (authClient) {
      await authClient.logout();
      setIsAuthenticated(false);
      setProfile(null);
      setActor(null);
      setCurrentQuest(null);
      setAnswer('');
      setFeedback('');
    }
  };

  if (!authClient) {
    return <div className="container">Loading...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div className="container">
        <h1>Welcome to Quizzy!</h1>
        <button onClick={login}>Login with Internet Identity</button>
        {error && <p className="error">{error}</p>}
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="container">
        <h1>Create Profile</h1>
        <div className="name-input-container">
          <input
            type="text"
            value={newDisplayName}
            onChange={(e) => {
              setNewDisplayName(e.target.value);
              checkNameAvailability(e.target.value);
            }}
            placeholder="Enter your display name"
          />
          {nameAvailabilityMessage && (
            <span className={nameAvailabilityMessage.includes('✓') ? 'available' : 'unavailable'}>
              {nameAvailabilityMessage}
            </span>
          )}
        </div>
        <button onClick={createProfile}>Create New Profile</button>
        {error && <p className="error">{error}</p>}
      </div>
    );
  }

  return (
    <div className="container">
      <div className="header">
        <h1>Quizzy</h1>
        <button className="logout-button" onClick={logout}>Logout</button>
      </div>
      
      <div className="profile">
        <h2>Profile</h2>
        <div className="player-name">
          {isEditingName ? (
            <div className="name-input-container">
              <input
                type="text"
                value={newDisplayName}
                onChange={(e) => {
                  setNewDisplayName(e.target.value);
                  checkNameAvailability(e.target.value);
                }}
                placeholder="Enter new display name"
              />
              {nameAvailabilityMessage && (
                <span className={nameAvailabilityMessage.includes('✓') ? 'available' : 'unavailable'}>
                  {nameAvailabilityMessage}
                </span>
              )}
              <div className="name-buttons">
                <button onClick={changeDisplayName}>Save</button>
                <button onClick={() => {
                  setIsEditingName(false);
                  setNewDisplayName('');
                  setNameAvailabilityMessage(null);
                }}>Cancel</button>
              </div>
            </div>
          ) : (
            <div className="display-name">
              <p>Player: {profile?.displayName || 'Unknown'}</p>
              <button className="edit-name-button" onClick={() => setIsEditingName(true)}>
                ✏️ Change Name
              </button>
            </div>
          )}
        </div>
        {profile?.subjectProgress && Array.isArray(profile.subjectProgress) && (
          <div>
            {profile.subjectProgress.map((progress: any) => {
              const [subject, data] = progress;
              const currentXp = data && typeof data === 'object' ? Number(data.xp) : 0;
              const xpThreshold = getXpThreshold(currentXp);
              const credits = data && typeof data === 'object' ? Number(data.credits) || 0 : 0;
              return (
                <div key={subject || 'unknown'} className="subject-progress">
                  <div className="subject-header">
                    <h3>Subject: {subject || 'Unknown'}</h3>
                    <div className="credits">
                      <span className="credits-icon">🪙</span>
                      <span>{credits} Credits</span>
                    </div>
                  </div>
                  <p>Level: {data && typeof data === 'object' ? Number(data.level) : 0}</p>
                  <p>XP: {currentXp} / {xpThreshold}</p>
                  <div className="xp-bar">
                    <div 
                      className="xp-progress" 
                      style={{ width: `${Math.min(100, (currentXp / xpThreshold) * 100)}%` }}
                    />
                  </div>
                  <p>Quests Completed: {data && typeof data === 'object' ? Number(data.questsCompleted) : 0}</p>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <div className="quest">
        <h2>Math Quest</h2>
        <button onClick={generateQuest}>Generate New Quest</button>
        
        {currentQuest && (
          <div>
            <p>{currentQuest.content?.question || 'Error loading question'}</p>
            <div className="quest-rewards">
              <span className="reward">
                <span className="reward-icon">⭐</span>
                <span>{Number(currentQuest.xpReward) || 0} XP</span>
              </span>
              <span className="reward">
                <span className="reward-icon">🪙</span>
                <span>{Number(currentQuest.creditReward) || 0} Credits</span>
              </span>
            </div>
            <input
              type="text"
              value={answer}
              onChange={(e) => setAnswer(e.target.value)}
              placeholder="Enter your answer"
            />
            <button onClick={submitAnswer}>Submit</button>
            {feedback && <p className={feedback.includes('Correct') ? 'correct' : 'wrong'}>{feedback}</p>}
          </div>
        )}
      </div>
      
      {error && <p className="error">{error}</p>}
    </div>
  );
};

export default App; 