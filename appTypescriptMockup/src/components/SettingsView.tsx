import React, { useRef } from 'react';
import { 
  Bluetooth,
  Wifi,
  Bell,
  Lock,
  Database,
  Info,
  ChevronRight,
  Cpu,
  Languages,
  Palette
} from 'lucide-react';
import { Card, Button } from './UI';
import { useSettings, translations } from '../lib/SettingsContext';
import { cn } from '../lib/utils';

export const SettingsView: React.FC = () => {
  const { theme, toggleTheme, language, setLanguage } = useSettings();
  const t = translations[language];
  const scrollRef = useRef<HTMLDivElement>(null);
  const [activeSection, setActiveSection] = React.useState('pref');

  const sections = [
    {
      id: 'pref',
      title: language === 'it' ? 'Preferenze App' : 'App Preferences',
      items: [
        { 
          label: t.theme, 
          icon: Palette, 
          sub: theme === 'dark' ? (language === 'it' ? 'Modalità Scura' : 'Dark Mode') : (language === 'it' ? 'Modalità Chiara' : 'Light Mode'), 
          custom: (
            <div className="flex bg-stormy-teal/5 p-1 rounded-2xl border border-stormy-teal/10 shrink-0">
              <button 
                onClick={toggleTheme}
                className={cn("px-5 py-2 rounded-xl text-xs font-bold transition-all", theme === 'light' ? "bg-stormy-teal text-white shadow-lg" : "opacity-40 italic")}
              >
                Light
              </button>
              <button 
                onClick={toggleTheme}
                className={cn("px-5 py-2 rounded-xl text-xs font-bold transition-all", theme === 'dark' ? "bg-stormy-teal text-white shadow-lg" : "opacity-40 italic")}
              >
                Dark
              </button>
            </div>
          )
        },
        { 
          label: t.language, 
          icon: Languages, 
          sub: language === 'it' ? 'Italiano' : 'English',
          custom: (
            <div className="flex bg-stormy-teal/5 p-1 rounded-2xl border border-stormy-teal/10 shrink-0">
              <button 
                onClick={() => setLanguage('it')}
                className={cn("px-5 py-2 rounded-xl text-xs font-bold transition-all", language === 'it' ? "bg-stormy-teal text-white shadow-lg" : "opacity-40 italic")}
              >
                IT
              </button>
              <button 
                onClick={() => setLanguage('en')}
                className={cn("px-5 py-2 rounded-xl text-xs font-bold transition-all", language === 'en' ? "bg-stormy-teal text-white shadow-lg" : "opacity-40 italic")}
              >
                EN
              </button>
            </div>
          )
        },
      ]
    },
    {
      id: 'conn',
      title: language === 'it' ? 'Connettività' : 'Connectivity',
      items: [
        { label: t.raspberryPairing, icon: Bluetooth, sub: language === 'it' ? 'Stato: Connesso via BLE' : 'Status: Connected via BLE', action: language === 'it' ? 'Config' : 'Setup' },
        { label: t.wifiHome, icon: Wifi, sub: 'Rete: Home_Fastweb_Gate', action: language === 'it' ? 'Mod' : 'Edit' },
      ]
    },
    {
      id: 'notif',
      title: language === 'it' ? 'Notifiche e Alert' : 'Notifications & Alerts',
      items: [
        { label: t.pushNotifications, icon: Bell, sub: t.activeNotifications, toggle: true },
        { label: t.audioHub, icon: Info, sub: t.doorBeeper, action: 'Test' },
      ]
    },
    {
      id: 'sys',
      title: language === 'it' ? 'Sistema' : 'System',
      items: [
        { label: t.databaseBackup, icon: Database, sub: t.lastBackup, action: language === 'it' ? 'Sinc' : 'Sync' },
        { label: t.firmware, icon: Cpu, sub: 'v1.4.2 (Up-to-date)', action: 'Update' },
      ]
    }
  ];

  React.useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveSection(entry.target.id);
          }
        });
      },
      { threshold: 0.5, rootMargin: '-10% 0px -60% 0px' }
    );

    sections.forEach((s) => {
      const el = document.getElementById(s.id);
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, [sections]);

  const scrollTo = (id: string) => {
    const el = document.getElementById(id);
    el?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <div className="flex flex-col md:flex-row gap-10">
      {/* Settings Side Nav (Desktop only) */}
      <div className="hidden md:block w-48 sticky top-24 h-fit">
        <h2 className="text-xl font-bold mb-6 italic">{t.settings}</h2>
        <div className="space-y-4">
          {sections.map(s => (
            <button 
              key={s.id}
              onClick={() => scrollTo(s.id)}
              className={cn(
                "block text-[10px] font-black uppercase tracking-[0.2em] transition-all text-left w-full",
                activeSection === s.id ? "text-stormy-teal translate-x-2" : "opacity-30 hover:opacity-100"
              )}
            >
              <div className="flex items-center gap-2">
                {activeSection === s.id && <div className="w-2 h-2 bg-stormy-teal rounded-full" />}
                {s.title}
              </div>
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 space-y-12 pb-32 md:pb-10" ref={scrollRef}>
        <div className="md:hidden">
          <h2 className="text-3xl font-bold italic">{t.settings}</h2>
          <p className="opacity-40 text-sm mt-1 italic">{t.configureHub}</p>
        </div>

        {sections.map((section) => (
          <div key={section.id} id={section.id} className="space-y-4 scroll-mt-24">
            <h3 className={cn(
              "text-xs font-black uppercase tracking-[0.2em] border-b pb-2",
              activeSection === section.id ? "text-stormy-teal border-stormy-teal/30" : "opacity-20 border-transparent"
            )}>
              {section.title}
            </h3>
            <Card variant="solid" className="divide-y border-stormy-teal/10 p-0 overflow-hidden bento-card divide-stormy-teal/5 rounded-[2.5rem]">
              {section.items.map((item, i) => (
                <div 
                  key={i} 
                  className="flex flex-col sm:flex-row sm:items-center justify-between p-7 hover:bg-stormy-teal/5 transition-all text-left gap-6 sm:gap-4"
                >
                  <div className="flex items-center gap-5">
                    <div className="p-4 rounded-[2rem] bg-stormy-teal/5 text-stormy-teal shrink-0">
                      <item.icon className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="font-bold text-base tracking-tight leading-none mb-1.5">{item.label}</p>
                      <p className="text-xs opacity-40 italic leading-relaxed max-w-[240px]">{item.sub}</p>
                    </div>
                  </div>
                  
                  <div className="flex justify-end shrink-0">
                    {item.custom ? item.custom : item.toggle ? (
                      <div className="w-12 h-6 bg-stormy-teal/20 rounded-full relative p-1 cursor-pointer">
                        <div className="w-4 h-4 bg-stormy-teal rounded-full" />
                      </div>
                    ) : (
                      <Button variant="ghost" size="sm" className="text-stormy-teal border border-stormy-teal/10 px-4 h-9 font-bold text-[10px] tracking-widest uppercase hover:bg-stormy-teal/5">
                        {item.action}
                        <ChevronRight className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </div>
              ))}
            </Card>
          </div>
        ))}

        <div className="pt-10 flex flex-col items-center gap-4 border-t border-stormy-teal/10 text-center opacity-20 hover:opacity-100 transition-opacity">
          <p className="text-[10px] uppercase font-black tracking-widest leading-loose">
            GateKeeper Smart System © 2024<br/>
            Progetto IoT Quinta Superiore
          </p>
          <div className="flex gap-6">
             <Button variant="ghost" size="sm" className="text-[10px] tracking-widest uppercase">Docs</Button>
             <Button variant="ghost" size="sm" className="text-[10px] tracking-widest uppercase">Support</Button>
          </div>
        </div>
      </div>
    </div>
  );
};
