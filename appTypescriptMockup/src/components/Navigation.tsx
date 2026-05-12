import React from 'react';
import { motion } from 'motion/react';
import { 
  Home, 
  Package, 
  Users, 
  History, 
  Settings, 
  LogOut,
  ShieldCheck
} from 'lucide-react';
import { cn } from '../lib/utils';
import { useSettings, translations } from '../lib/SettingsContext';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, setActiveTab }) => {
  const { theme, language } = useSettings();
  const t = translations[language];

  const navItems = [
    { id: 'dashboard', label: t.dashboard, icon: Home },
    { id: 'objects', label: t.objects, icon: Package },
    { id: 'users', label: t.members, icon: Users },
    { id: 'events', label: t.history, icon: History },
    { id: 'settings', label: t.settings, icon: Settings },
  ];

  return (
    <aside className={cn(
      "hidden md:flex flex-col w-28 h-screen border-r sticky top-0 py-8 items-center space-y-12 transition-colors",
      theme === 'dark' ? "bg-dark-bg border-dark-border" : "bg-light-card border-light-border"
    )}>
      <div className="w-16 h-16 rounded-2xl flex items-center justify-center shrink-0 overflow-hidden">
        <img src="/logo.png" alt="GateKeeper Logo" className="w-full h-full object-contain" onError={(e) => {
          e.currentTarget.style.display = 'none';
          e.currentTarget.parentElement!.innerHTML = `<div class="w-full h-full ${theme === 'dark' ? 'bg-orange-gold text-dark-bg' : 'bg-stormy-teal text-white'} flex items-center justify-center font-bold">GK</div>`;
        }} />
      </div>

      <nav className="flex-1 flex flex-col space-y-6">
        {navItems.map((item) => (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className={cn(
              "p-3 rounded-2xl transition-all relative group",
              activeTab === item.id 
                ? "bg-stormy-teal text-white shadow-lg shadow-stormy-teal/20" 
                : "text-charcoal-blue/60 hover:text-stormy-teal"
            )}
          >
            <item.icon className="w-7 h-7" />
            
            <span className="absolute left-full ml-4 px-2 py-1 bg-stormy-teal text-white text-[10px] font-bold uppercase tracking-widest rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
              {item.label}
            </span>
          </button>
        ))}
      </nav>

      <div className="mb-4">
        <button 
          onClick={() => setActiveTab('account')}
          className={cn(
            "w-12 h-12 rounded-full border-2 p-0.5 cursor-pointer hover:scale-105 transition-all duration-300",
            activeTab === 'account' ? "border-stormy-teal bg-stormy-teal/10" : "border-stormy-teal/20"
          )}
        >
          <div className="w-full h-full rounded-full bg-charcoal-blue/20 flex items-center justify-center text-xs font-black italic">
            M
          </div>
        </button>
      </div>
    </aside>
  );
};

export const BottomNav: React.FC<SidebarProps> = ({ activeTab, setActiveTab }) => {
  const { language } = useSettings();
  const t = translations[language];

  const navItems = [
    { id: 'dashboard', label: t.dashboard, icon: Home },
    { id: 'objects', label: t.objects, icon: Package },
    { id: 'users', label: t.members, icon: Users },
    { id: 'events', label: 'Log', icon: History }
  ];

  return (
    <div className="md:hidden fixed bottom-6 left-1/2 -translate-x-1/2 w-[90%] max-w-sm z-50">
      <nav className="glass-dark rounded-full px-6 py-3 flex justify-between items-center shadow-2xl shadow-black/20">
        {navItems.map((item) => (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className={cn(
              "flex flex-col items-center gap-1 transition-all flex-1",
              activeTab === item.id ? "text-stormy-teal" : "opacity-40"
            )}
          >
            <div className={cn(
              "p-2 rounded-2xl transition-colors",
              activeTab === item.id ? "bg-stormy-teal/10" : ""
            )}>
              <item.icon className="w-5 h-5 mx-auto" />
            </div>
            <span className="text-[7px] font-black uppercase tracking-[0.2em]">{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  );
};
