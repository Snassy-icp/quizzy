import React, { useState, useEffect } from 'react';
import { AuthClient } from '@dfinity/auth-client';
import { Actor, HttpAgent } from '@dfinity/agent';
import { quizzy_backend } from '../../../src/declarations/quizzy_backend';
import type { _SERVICE } from '../../../src/declarations/quizzy_backend/quizzy_backend.did.d.ts';

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
    const identity = client.getIdentity();
    const agent = new HttpAgent({ identity });
    // TODO: when deploying locally, remove this line
    await agent.fetchRootKey();
    
    // Create a new actor with the identity
    const newActor = Actor.createActor<_SERVICE>(quizzy_backend._factory, {
      agent,
      canisterId: window.ENV?.QUIZZY_BACKEND_CANISTER_ID || process.env.QUIZZY_BACKEND_CANISTER_ID!,
    });
    setActor(newActor);
    
    // Try to get existing profile
    try {
      const profile = await newActor.getProfile();
      if (profile) {
        setProfile(profile);
      }
    } catch (e) {
      console.error('Error fetching profile:', e);
    }
  };

  // Login with Internet Identity
  const login = async () => {
    if (authClient) {
      await authClient.login({
        identityProvider: window.ENV?.II_URL || process.env.II_URL,
        onSuccess: () => {
          setIsAuthenticated(true);
          initActor(authClient);
        },
      });
    }
  };

  // Create profile if doesn't exist
  const createProfile = async () => {
    if (actor) {
      try {
        const newProfile = await actor.createProfile('Player ' + Math.floor(Math.random() * 1000));
        setProfile(newProfile);
      } catch (e) {
        console.error('Error creating profile:', e);
      }
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
      } catch (e) {
        console.error('Error generating quest:', e);
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
          // Get updated profile after correct answer
          const updatedProfile = await actor.getProfile();
          setProfile(updatedProfile);
        }
      } catch (e) {
        console.error('Error submitting answer:', e);
      }
    }
  };

  if (!authClient) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div className="container">
        <h1>Welcome to Quizzy!</h1>
        <button onClick={login}>Login with Internet Identity</button>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="container">
        <h1>Create Profile</h1>
        <button onClick={createProfile}>Create New Profile</button>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Quizzy</h1>
      
      <div className="profile">
        <h2>Profile</h2>
        <p>Player: {profile.displayName}</p>
        {profile.subjectProgress.map((progress: any) => (
          <div key={progress[0]}>
            <p>Subject: {progress[0]}</p>
            <p>Level: {progress[1].level}</p>
            <p>XP: {progress[1].xp}</p>
          </div>
        ))}
      </div>

      <div className="quest">
        <h2>Math Quest</h2>
        <button onClick={generateQuest}>Generate New Quest</button>
        
        {currentQuest && (
          <div>
            <p>{currentQuest.content.question}</p>
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
    </div>
  );
};

export default App; 