/**
 * Defines the data structures for GateKeeper
 */

export enum UserRole {
  ADMIN = 'admin',
  ADULT = 'adult',
  CHILD = 'child'
}

export enum HomeStatus {
  SAFE = 'safe',
  ALERT = 'alert',
  AWAY = 'away'
}

export interface User {
  id: string;
  name: string;
  role: UserRole;
  isInside: boolean;
  avatarUrl?: string;
  lastSeen?: string;
}

export interface SmartObject {
  id: string;
  name: string;
  tagId: string; // RFID Tag
  isInside: boolean;
  ownerId?: string; // Optional: associated with a specific person
  category: 'keys' | 'wallet' | 'umbrella' | 'bag' | 'other';
  lastMovement?: string;
  icon?: any;
}

export interface GateEvent {
  id: string;
  timestamp: string;
  userId?: string;
  objectId?: string;
  type: 'entry' | 'exit' | 'risk';
  description: {
    it: string;
    en: string;
  };
  severity: 'info' | 'warning' | 'critical';
  resolved?: boolean;
}

export type Theme = 'dark' | 'light';
export type Language = 'it' | 'en';
