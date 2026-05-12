import React, { createContext, useContext, useState, useEffect } from 'react';
import { Theme, Language } from '../types';

interface SettingsContextType {
  theme: Theme;
  language: Language;
  toggleTheme: () => void;
  setLanguage: (lang: Language) => void;
}

const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export const SettingsProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setTheme] = useState<Theme>('dark');
  const [language, setLanguage] = useState<Language>('it');

  useEffect(() => {
    document.documentElement.className = theme;
  }, [theme]);

  const toggleTheme = () => setTheme(prev => prev === 'dark' ? 'light' : 'dark');

  return (
    <SettingsContext.Provider value={{ theme, language, toggleTheme, setLanguage }}>
      {children}
    </SettingsContext.Provider>
  );
};

export const useSettings = () => {
  const context = useContext(SettingsContext);
  if (!context) throw new Error('useSettings must be used within SettingsProvider');
  return context;
};

export const translations = {
  it: {
    dashboard: 'Dashboard',
    objects: 'Oggetti',
    members: 'Membri',
    settings: 'Impostazioni',
    history: 'Cronologia',
    allSecure: 'TUTTO SICURO',
    hazardsDetected: 'Rischi Rilevati',
    unresolvedAlerts: 'ALERT DA RISOLVERE',
    usersInside: 'Utenti in Casa',
    lastSeen: 'Ultimo avvistamento',
    systemSmooth: 'Il sistema sta funzionando correttamente via Raspberry Pi 4.',
    addTag: 'AGGIUNGI TAG',
    liveEvents: 'Eventi Live',
    fullHistory: 'VEDI TUTTA LA STORIA',
    markResolved: 'Risolto',
    theme: 'Tema',
    language: 'Lingua',
    location: 'Localizzazione',
    lastSeenLabel: 'Ultimo avvistamento',
    currentStatus: 'Stato attuale',
    inside: 'IN CASA',
    outside: 'FUORI',
    pickedUp: 'PRELEVATO',
    outOfReach: 'FUORI PORTATA',
    inviteMember: 'Invita Membro',
    manageFamily: 'Gestisci chi ha accesso alla tua casa e i loro permessi.',
    monitorObjects: 'Controlla quali oggetti sono attualmente in casa o fuori.',
    configureHub: 'Configura il tuo GateKeeper hub hardware.',
    raspberryPairing: 'Accoppiamento Raspberry Pi',
    wifiHome: 'Wi-Fi Casa',
    pushNotifications: 'Notifiche Push',
    activeNotifications: 'Attivo per accessi e rischi',
    audioHub: 'Hub Audio',
    doorBeeper: 'Segnale acustico porta',
    databaseBackup: 'Database & Backup',
    lastBackup: 'Ultimo backup: 2 ore fa',
    firmware: 'Firmware',
    notifications: 'Notifiche',
    profileInfo: 'Informazioni Profilo',
    securitySettings: 'Impostazioni di Sicurezza',
    logout: 'Disconnetti',
    account: 'Account',
    searchEvents: 'Cerca eventi...',
    viewDay: 'Giorno',
    viewWeek: 'Settimana',
    viewMonth: 'Mese',
    all: 'Tutte',
    critical: 'Critici',
    info: 'Info',
    activeSessions: 'Sessioni Attive',
    mfaActive: 'MFA Attivo',
    onlineNow: 'In linea ora',
    close: 'Chiudi',
    markAsRead: 'Segna come letti',
    noNotifications: 'Nessuna nuova notifica'
  },
  en: {
    dashboard: 'Dashboard',
    objects: 'Objects',
    members: 'Members',
    settings: 'Settings',
    history: 'History',
    allSecure: 'ALL SECURE',
    hazardsDetected: 'Hazards Detected',
    unresolvedAlerts: 'ALERTS TO RESOLVE',
    usersInside: 'Users Inside',
    lastSeen: 'Last sighting',
    systemSmooth: 'System is running smoothly via Raspberry Pi 4.',
    addTag: 'ADD TAG',
    liveEvents: 'Live Events',
    fullHistory: 'VIEW FULL HISTORY',
    markResolved: 'Resolve',
    theme: 'Theme',
    language: 'Language',
    location: 'Location',
    lastSeenLabel: 'Last sighting',
    currentStatus: 'Current Status',
    inside: 'INSIDE',
    outside: 'OUTSIDE',
    pickedUp: 'PICKED UP',
    outOfReach: 'OUT OF REACH',
    inviteMember: 'Invite Member',
    manageFamily: 'Manage family access and permissions.',
    monitorObjects: 'Check which objects are currently inside or outside.',
    configureHub: 'Configure your GateKeeper hardware hub.',
    raspberryPairing: 'Raspberry Pi Pairing',
    wifiHome: 'Wi-Fi Home',
    pushNotifications: 'Push Notifications',
    activeNotifications: 'Active for entries & risks',
    audioHub: 'Audio Hub',
    doorBeeper: 'Door beeper volume',
    databaseBackup: 'Database & Backup',
    lastBackup: 'Last backup: 2h ago',
    firmware: 'Firmware',
    notifications: 'Notifications',
    profileInfo: 'Profile Information',
    securitySettings: 'Security Settings',
    logout: 'Log Out',
    account: 'Account',
    searchEvents: 'Search events...',
    viewDay: 'Day',
    viewWeek: 'Week',
    viewMonth: 'Month',
    all: 'All',
    critical: 'Critical',
    info: 'Info',
    activeSessions: 'Active Sessions',
    mfaActive: 'MFA Active',
    onlineNow: 'Online now',
    close: 'Close',
    markAsRead: 'Mark all as read',
    noNotifications: 'No new notifications'
  }
};
