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

  // Create profile if doesn't exist
  const createProfile = async () => {
    if (actor) {
      try {
        console.log('Creating profile...');
        const displayName = 'Player ' + Math.floor(Math.random() * 1000);
        console.log('Using display name:', displayName);
        const newProfile = await actor.createProfile(displayName);
        console.log('Profile created (full data):', JSON.stringify(newProfile, bigIntReplacer, 2));
        if (newProfile) {
          setProfile(newProfile);
          setError(null);
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

  // Generate new math quest
  const generateQuest = async () => {
    if (actor) {
      try {
        const quest = await actor.generateMathQuest(1);
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
        <button onClick={createProfile}>Create New Profile</button>
        {error && <p className="error">{error}</p>}
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Quizzy</h1>
      
      <div className="profile">
        <h2>Profile</h2>
        <p>Player: {profile?.displayName || 'Unknown'}</p>
        {profile?.subjectProgress && Array.isArray(profile.subjectProgress) && (
          <div>
            {profile.subjectProgress.map((progress: any) => {
              const [subject, data] = progress;
              return (
                <div key={subject || 'unknown'}>
                  <p>Subject: {subject || 'Unknown'}</p>
                  <p>Level: {data && typeof data === 'object' ? Number(data.level) : 0}</p>
                  <p>XP: {data && typeof data === 'object' ? Number(data.xp) : 0}</p>
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