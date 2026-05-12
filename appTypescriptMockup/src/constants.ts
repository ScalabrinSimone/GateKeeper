import { User, SmartObject, GateEvent, UserRole } from './types';
import { Key, Umbrella, Package } from 'lucide-react';

export const MOCK_USERS: User[] = [
  {
    id: 'u1',
    name: 'Marco (Admin)',
    role: UserRole.ADMIN,
    isInside: true,
    lastSeen: new Date().toISOString(),
  },
  {
    id: 'u2',
    name: 'Elena',
    role: UserRole.ADULT,
    isInside: false,
    lastSeen: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: 'u3',
    name: 'Luca',
    role: UserRole.CHILD,
    isInside: true,
    lastSeen: new Date().toISOString(),
  },
];

export const MOCK_OBJECTS: SmartObject[] = [
  {
    id: 'o1',
    name: 'Chiavi Auto',
    tagId: 'RFID_001',
    isInside: true,
    category: 'keys',
    icon: Key,
  },
  {
    id: 'o2',
    name: 'Ombrello Rosso',
    tagId: 'RFID_002',
    isInside: true,
    category: 'umbrella',
    icon: Umbrella,
  },
  {
    id: 'o3',
    name: 'Zaino Scuola',
    tagId: 'RFID_003',
    isInside: true,
    category: 'bag',
    ownerId: 'u3',
    icon: Package,
  },
];

export const MOCK_EVENTS: GateEvent[] = [
  {
    id: 'e1',
    timestamp: new Date().toISOString(),
    userId: 'u1',
    type: 'entry',
    description: {
      it: 'Marco è rientrato in casa.',
      en: 'Marco entered the house.'
    },
    severity: 'info',
  },
  {
    id: 'e2',
    timestamp: new Date(Date.now() - 1500000).toISOString(),
    objectId: 'o2',
    type: 'exit',
    description: {
      it: 'Ombrello Rosso portato fuori (Previsto sole).',
      en: 'Red Umbrella taken out (Sun predicted).'
    },
    severity: 'info',
  },
  {
    id: 'e3',
    timestamp: new Date(Date.now() - 5000000).toISOString(),
    userId: 'u3',
    type: 'risk',
    description: {
      it: 'Luca è uscito senza il suo telefono!',
      en: 'Luca left without his phone!'
    },
    severity: 'critical',
    resolved: false
  },
  {
    id: 'e4',
    timestamp: new Date(Date.now() - 7200000).toISOString(),
    objectId: 'o1',
    type: 'risk',
    description: {
      it: 'Chiavi dimenticate nella serratura esterna.',
      en: 'Keys forgotten in the external lock.'
    },
    severity: 'critical',
    resolved: false
  },
];
