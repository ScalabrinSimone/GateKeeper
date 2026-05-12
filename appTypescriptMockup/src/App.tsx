/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, useEffect } from 'react';
import { Sidebar, BottomNav } from './components/Navigation';
import { Dashboard } from './components/Dashboard';
import { MembersView } from './components/MembersView';
import { ObjectsView } from './components/ObjectsView';
import { SettingsView } from './components/SettingsView';
import { AccountView } from './components/AccountView';
import { NotificationsView } from './components/NotificationsView';
import { EventsView } from './components/EventsView';
import { motion, AnimatePresence } from 'motion/react';
import { Bell, Sun, Moon, User, ChevronDown, Globe, LogOut, Settings as SettingsIcon } from 'lucide-react';
import { SettingsProvider, useSettings, translations } from './lib/SettingsContext';
import { cn } from './lib/utils';

function AppContent() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const { theme, toggleTheme, language, setLanguage } = useSettings();
  const t = translations[language];

  // Close dropdown on tab change
  useEffect(() => {
    setDropdownOpen(false);
  }, [activeTab]);

  // Force language sync for specific system texts
  useEffect(() => {
    document.documentElement.lang = language;
  }, [language]);

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'objects':
        return <ObjectsView />;
      case 'users':
        return <MembersView />;
      case 'events':
        return <EventsView />;
      case 'notifications':
        return <NotificationsView />;
      case 'settings':
        return <SettingsView />;
      case 'account':
        return <AccountView />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className={`min-h-screen flex font-sans transition-colors duration-500 ${theme === 'dark' ? 'dark bg-dark-bg text-dark-text' : 'light bg-light-bg text-light-text'}`}>
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />
      <BottomNav activeTab={activeTab} setActiveTab={setActiveTab} />

      <main className="flex-1 flex flex-col min-w-0">
        <header className="flex items-center justify-between px-6 py-4 sticky top-0 bg-transparent backdrop-blur-xl z-50 border-b border-stormy-teal/10">
          <div className="flex items-center gap-2 h-10 overflow-hidden">
            <img src="/logo.png" alt="GateKeeper Logo" className="h-full object-contain" onError={(e) => {
              e.currentTarget.style.display = 'none';
              e.currentTarget.parentElement!.innerHTML = `<div class="flex items-center gap-2"><div class="w-8 h-8 ${theme === 'dark' ? 'bg-orange-gold text-dark-bg' : 'bg-stormy-teal text-white'} rounded-lg flex items-center justify-center font-bold text-xs">GK</div><h1 class="text-lg font-bold">GateKeeper</h1></div>`;
            }} />
          </div>
          
          <div className="flex items-center gap-2 sm:gap-4 relative">
            {/* Desktop Notification Button */}
            <button 
              onClick={() => setActiveTab('notifications')}
              className={cn(
                "p-2.5 rounded-full transition-all active:scale-90 relative",
                activeTab === 'notifications' ? "bg-stormy-teal text-white shadow-lg" : "bg-charcoal-blue/10 hover:bg-charcoal-blue/20"
              )}
            >
              <Bell className="w-5 h-5" />
              <div className="absolute top-2 right-2 w-2 h-2 bg-orange-gold rounded-full border-2 border-dark-card" />
            </button>

            {/* Account & Quick Menu Dropdown */}
            <div className="relative">
              <button 
                onClick={() => setDropdownOpen(!dropdownOpen)}
                className="flex items-center gap-2.5 pl-1 pr-3 py-1 bg-charcoal-blue/10 hover:bg-charcoal-blue/20 rounded-full transition-all active:scale-95 group border border-transparent hover:border-stormy-teal/20"
              >
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-stormy-teal to-charcoal-blue flex items-center justify-center text-white text-[10px] font-black italic shadow-md">
                  M
                </div>
                <ChevronDown className={cn("w-4 h-4 opacity-40 transition-transform duration-300", dropdownOpen && "rotate-180")} />
              </button>

              <AnimatePresence>
                {dropdownOpen && (
                  <>
                    <div 
                      className="fixed inset-0 z-0" 
                      onClick={() => setDropdownOpen(false)} 
                    />
                    <motion.div
                      initial={{ opacity: 0, y: 10, scale: 0.95 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: 10, scale: 0.95 }}
                      className={cn(
                        "absolute right-0 mt-4 w-64 backdrop-blur-2xl border rounded-[2rem] shadow-2xl z-10 overflow-hidden p-2",
                        theme === 'dark' ? "bg-dark-card/90 border-stormy-teal/20" : "bg-white/90 border-stormy-teal/10 shadow-stormy-teal/10"
                      )}
                    >
                      <div className={cn(
                        "p-4 border-b mb-2",
                        theme === 'dark' ? "border-stormy-teal/10" : "border-stormy-teal/5"
                      )}>
                        <p className="text-xs font-black uppercase tracking-widest opacity-40 mb-1">Account</p>
                        <p className="font-bold text-sm tracking-tight truncate">Marco Rossi</p>
                      </div>

                      <div className="space-y-1">
                        <button 
                          onClick={() => {
                            setActiveTab('account');
                            setDropdownOpen(false);
                          }}
                          className={cn(
                            "w-full flex items-center gap-3 px-4 py-3 rounded-2xl transition-colors text-left",
                            theme === 'dark' ? "hover:bg-stormy-teal/10" : "hover:bg-stormy-teal/5"
                          )}
                        >
                          <User className="w-4 h-4 text-stormy-teal" />
                          <span className="text-sm font-bold tracking-tight">{t.account}</span>
                        </button>

                        <button 
                          onClick={() => {
                            setActiveTab('settings');
                            setDropdownOpen(false);
                          }}
                          className={cn(
                            "w-full flex items-center gap-3 px-4 py-3 rounded-2xl transition-colors text-left",
                            theme === 'dark' ? "hover:bg-stormy-teal/10" : "hover:bg-stormy-teal/5"
                          )}
                        >
                          <SettingsIcon className="w-4 h-4 text-stormy-teal" />
                          <span className="text-sm font-bold tracking-tight">{t.settings}</span>
                        </button>
                      </div>

                      <div className="h-px bg-stormy-teal/10 my-2 mx-4" />

                      <div className="p-2 space-y-2">
                        <div className="flex items-center justify-between px-3 py-2">
                          <div className="flex items-center gap-2 opacity-60">
                            {theme === 'dark' ? <Moon className="w-3.5 h-3.5" /> : <Sun className="w-3.5 h-3.5" />}
                            <span className="text-[10px] font-black uppercase tracking-widest">{t.theme}</span>
                          </div>
                          <button 
                            onClick={toggleTheme}
                            className="w-10 h-5 bg-stormy-teal/20 rounded-full relative p-0.5 border border-stormy-teal/10 group active:scale-90 transition-transform"
                          >
                            <div className={cn(
                              "w-3.5 h-3.5 bg-stormy-teal rounded-full transition-all duration-300",
                              theme === 'dark' ? "translate-x-5" : "translate-x-0"
                            )} />
                          </button>
                        </div>

                        <div className="flex items-center justify-between px-3 py-2">
                          <div className="flex items-center gap-2 opacity-60">
                            <Globe className="w-3.5 h-3.5" />
                            <span className="text-[10px] font-black uppercase tracking-widest">{t.language}</span>
                          </div>
                          <div className="flex bg-stormy-teal/5 rounded-lg p-0.5 border border-stormy-teal/10">
                            {(['it', 'en'] as const).map(lang => (
                              <button 
                                key={lang} 
                                onClick={() => setLanguage(lang)}
                                className={cn(
                                  "w-8 h-6 flex items-center justify-center text-[8px] font-black rounded-md transition-all",
                                  language === lang ? "bg-stormy-teal text-white" : "opacity-30"
                                )}
                              >
                                {lang.toUpperCase()}
                              </button>
                            ))}
                          </div>
                        </div>
                      </div>

                      <div className="mt-2 p-1">
                        <button className="w-full flex items-center justify-center gap-2 py-3 rounded-2xl bg-red-500/5 hover:bg-red-500/10 text-red-500 transition-colors">
                          <LogOut className="w-4 h-4" />
                          <span className="text-xs font-black uppercase tracking-widest">{t.logout}</span>
                        </button>
                      </div>
                    </motion.div>
                  </>
                )}
              </AnimatePresence>
            </div>
          </div>
        </header>

        <div className="p-6 md:p-10 max-w-7xl mx-auto w-full flex-1">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, scale: 0.98 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 1.02 }}
              transition={{ duration: 0.2, ease: "easeOut" }}
            >
              {renderContent()}
            </motion.div>
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}

export default function App() {
  return (
    <SettingsProvider>
      <AppContent />
    </SettingsProvider>
  );
}
