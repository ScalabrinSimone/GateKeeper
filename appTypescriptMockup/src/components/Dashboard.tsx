import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  AlertTriangle, 
  MapPin,
  Clock,
  Plus,
  ShieldCheck,
  Cpu,
  CheckCircle,
  Package
} from 'lucide-react';
import { Card, Button } from './UI';
import { MOCK_USERS, MOCK_OBJECTS, MOCK_EVENTS as INITIAL_EVENTS } from '../constants';
import { GateEvent } from '../types';
import { cn } from '../lib/utils';
import { useSettings, translations } from '../lib/SettingsContext';

export const Dashboard: React.FC = () => {
  const { language, setLanguage, theme } = useSettings();
  const t = translations[language];
  const [events, setEvents] = useState<GateEvent[]>(INITIAL_EVENTS);

  const unresolvedAlerts = events.filter(e => e.severity === 'critical' && e.resolved === false);
  const isSecure = unresolvedAlerts.length === 0;

  const sortedUsers = [...MOCK_USERS].sort((a, b) => (a.isInside === b.isInside ? 0 : a.isInside ? -1 : 1));
  const peopleInside = MOCK_USERS.filter(u => u.isInside);
  const objectsOutside = MOCK_OBJECTS.filter(o => !o.isInside);

  const resolveEvent = (id: string) => {
    setEvents(prev => prev.map(e => e.id === id ? { ...e, resolved: true } : e));
  };

  return (
    <div className="space-y-8 pb-32 md:pb-10">
      {/* Header Status */}
      <motion.section 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between gap-6"
      >
        <div>
          <h2 className="text-4xl font-bold tracking-tight">{t.dashboard}</h2>
          <p className="opacity-40 flex items-center gap-2 mt-1 font-medium italic">
            <MapPin className="w-4 h-4" /> Via Roma, 12 - Milano • {t.systemSmooth}
          </p>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex bg-stormy-teal/5 p-1 rounded-xl h-10 border border-stormy-teal/10">
            {(['it', 'en'] as const).map(lang => (
              <button 
                key={lang}
                onClick={() => setLanguage(lang)}
                className={cn(
                  "px-3 rounded-lg text-[10px] font-black uppercase transition-all",
                  language === lang ? "bg-stormy-teal text-white shadow-md shadow-stormy-teal/20" : "opacity-30 hover:opacity-100 italic"
                )}
              >
                {lang}
              </button>
            ))}
          </div>
          <div className="hidden sm:flex items-center px-4 py-2 bento-card rounded-full h-10 border border-stormy-teal/10">
            <div className={cn("w-2 h-2 rounded-full mr-3 animate-pulse", isSecure ? "bg-stormy-teal" : "bg-orange-gold")} />
            <span className="text-[10px] font-bold tracking-widest uppercase opacity-60">Status: {isSecure ? 'Active' : 'Warning'}</span>
          </div>
          <Button variant="secondary" className="rounded-full font-bold h-10 px-6 shadow-lg shadow-orange-gold/10">
            <Plus className="w-4 h-4" /> {t.addTag}
          </Button>
        </div>
      </motion.section>

      {/* Grid Layout (Bento Style) */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
        {/* Main Status Block (Large) */}
        <Card variant="solid" className={cn(
          "md:col-span-2 lg:col-span-3 flex items-center relative overflow-hidden h-40 sm:h-48 md:h-64 order-1 md:order-none",
          !isSecure && "border-orange-gold shadow-lg shadow-orange-gold/10"
        )}>
          <div className="flex-1 z-10 px-4 sm:px-6 md:px-8">
            <p className="opacity-40 uppercase text-[10px] sm:text-xs font-bold tracking-widest mb-1 md:mb-2">{isSecure ? t.allSecure : t.hazardsDetected}</p>
            <h2 className={cn(
              "text-2xl sm:text-4xl md:text-6xl font-black italic leading-tight",
              isSecure ? "text-stormy-teal" : "text-orange-gold"
            )}>
              {isSecure ? (language === 'it' ? 'TUTTO SICURO' : 'ALL SECURE') : `${unresolvedAlerts.length} ${t.unresolvedAlerts}`}
            </h2>
            <p className={cn("mt-1 md:mt-2 text-[10px] sm:text-base font-bold tracking-tight opacity-60")}>
              {peopleInside.length} {t.usersInside} • {objectsOutside.length} {t.hazardsDetected}
            </p>
          </div>
          <div className={cn(
            "w-20 h-20 sm:w-24 sm:h-24 md:w-40 md:h-40 rounded-full flex items-center justify-center shrink-0 mr-3 sm:mr-4 md:mr-8",
            isSecure ? "bg-stormy-teal/10" : "bg-orange-gold/10"
          )}>
             {isSecure ? <ShieldCheck className="w-10 h-10 sm:w-12 sm:h-12 md:w-20 md:h-20 text-stormy-teal" /> : <AlertTriangle className="w-10 h-10 sm:w-12 sm:h-12 md:w-20 md:h-20 text-orange-gold animate-bounce" />}
          </div>
          <div className="absolute -right-8 -bottom-8 w-48 h-48 bg-orange-gold/5 rounded-full blur-3xl" />
        </Card>

        {/* System Health (Small) */}
        <Card variant="solid" className="flex flex-col justify-between order-2 md:order-none">
           <div className="flex items-center justify-between">
             <h3 className="text-lg font-bold">Raspberry Pi 4</h3>
             <Cpu className="w-5 h-5 text-stormy-teal" />
           </div>
           <div className="space-y-4">
              <div>
                <div className="flex justify-between text-[10px] font-bold uppercase tracking-widest opacity-40 mb-1">
                  <span>CPU Temp</span>
                  <span className="opacity-100">42°C</span>
                </div>
                <div className="h-1.5 bg-stormy-teal/10 rounded-full overflow-hidden">
                  <div className="h-full bg-stormy-teal w-[42%]" />
                </div>
              </div>
              <Button variant="ghost" size="sm" className="w-full text-[10px] tracking-widest border border-stormy-teal/10 hover:bg-stormy-teal/5 uppercase font-black">LOGS</Button>
           </div>
        </Card>

        {/* Recent Activity (Tall Sidebar in the bento layout) */}
        <Card variant="solid" className="md:col-span-1 lg:col-span-1 md:row-span-2 flex flex-col h-full lg:order-last min-h-[400px] order-4 md:order-none">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-xl font-bold">{t.liveEvents}</h3>
            <div className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 bg-orange-gold rounded-full animate-pulse" />
              <span className="text-[10px] font-black opacity-40 uppercase tracking-widest">Live</span>
            </div>
          </div>
          <div className="space-y-6 flex-1 overflow-y-auto pr-2 scrollbar-hide">
            <AnimatePresence initial={false}>
              {events.map((event) => (
                <motion.div 
                  key={event.id}
                  layout
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: event.resolved ? 0.3 : 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  className={cn(
                    "flex flex-col gap-2 p-3 rounded-2xl transition-all",
                    !event.resolved && event.severity === 'critical' ? "bg-orange-gold/10 border border-orange-gold/20" : "bg-white/5"
                  )}
                >
                  <div className="flex gap-4">
                    <div className={cn(
                      "p-2 rounded-xl shrink-0 h-10 w-10 flex items-center justify-center",
                      event.severity === 'critical' ? "bg-orange-gold text-dark-bg" : "bg-stormy-teal text-white"
                    )}>
                      {event.severity === 'critical' ? <AlertTriangle className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-bold leading-tight">{event.description[language]}</p>
                      <p className="text-[10px] font-bold opacity-30 uppercase tracking-widest mt-1">
                        {new Date(event.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </div>
                  {!event.resolved && event.severity === 'critical' && (
                    <Button 
                      variant="primary" 
                      size="sm" 
                      onClick={() => resolveEvent(event.id)}
                      className="w-full mt-2 bg-orange-gold text-dark-bg h-8 text-[10px] tracking-widest"
                    >
                      <CheckCircle className="w-3 h-3" /> {t.markResolved}
                    </Button>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
          <Button variant="ghost" className="w-full mt-6 text-xs border border-stormy-teal/10 rounded-xl py-3 tracking-widest font-black uppercase hover:bg-stormy-teal/5">{t.fullHistory}</Button>
        </Card>

        {/* Tracking Sections Grouped for order control */}
        <div className="md:col-span-2 lg:col-span-3 grid grid-cols-1 sm:grid-cols-2 gap-8 md:gap-6 order-3 md:order-none">
          <section className="space-y-6 order-1 md:order-none">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-black uppercase tracking-widest opacity-40 italic">{t.members}</h3>
            </div>
            <div className="flex gap-6 overflow-x-auto pb-8 pt-4 scrollbar-hide -mx-4 px-4">
              {sortedUsers.map((user) => (
                <div key={user.id} className="relative group shrink-0 w-20 transition-all duration-300 hover:scale-110 hover:-translate-y-1">
                  <div className={cn(
                    "w-20 aspect-square rounded-[2rem] bg-stormy-teal/5 flex items-center justify-center border-2 transition-all duration-300",
                    user.isInside ? "border-stormy-teal shadow-lg shadow-stormy-teal/20" : "border-transparent opacity-40 grayscale"
                  )}>
                    <span className={cn(
                      "text-xl font-black",
                      user.isInside ? "text-stormy-teal" : "opacity-40"
                    )}>{user.name[0]}</span>
                  </div>
                  {user.isInside && (
                    <motion.div 
                      layoutId={`active-dot-${user.id}`}
                      className={cn(
                        "absolute top-0 right-0 w-4 h-4 bg-stormy-teal rounded-full border-4 z-10",
                        theme === 'dark' ? "border-dark-card" : "border-white"
                      )}
                    />
                  )}
                  <p className="text-[10px] font-bold text-center mt-3 truncate w-full opacity-60 group-hover:opacity-100 transition-opacity whitespace-nowrap px-1 italic">
                    {user.name.split(' ')[0]}
                  </p>
                </div>
              ))}
              <button className="w-20 h-20 shrink-0 rounded-3xl border-2 border-dashed border-stormy-teal/20 flex items-center justify-center opacity-40 hover:opacity-100 hover:border-stormy-teal transition-all group">
                <Plus className="w-8 h-8 group-hover:scale-110 transition-transform" />
              </button>
            </div>
          </section>

          <section className="space-y-4 order-3 md:order-none">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-black uppercase tracking-widest opacity-40 italic">{t.objects}</h3>
            </div>
            <div className="grid grid-cols-1 gap-3">
              {MOCK_OBJECTS.map((obj) => (
                <div key={obj.id} className="bento-card p-4 rounded-[2rem] flex items-center justify-between border border-stormy-teal/10 bg-stormy-teal/5">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "p-3 rounded-2xl",
                      obj.isInside ? "bg-stormy-teal/10 text-stormy-teal" : "bg-orange-gold/10 text-orange-gold"
                    )}>
                      {obj.icon ? <obj.icon className="w-5 h-5" /> : <Package className="w-5 h-5" />}
                    </div>
                    <div>
                      <p className="font-bold text-sm tracking-tight">{obj.name}</p>
                      <p className="text-[10px] opacity-40 uppercase font-black italic">Tag: {obj.tagId}</p>
                    </div>
                  </div>
                  <div className={cn(
                    "px-3 py-1 rounded-full text-[10px] font-black tracking-widest",
                    obj.isInside ? "text-stormy-teal bg-stormy-teal/10" : "text-orange-gold bg-orange-gold/10"
                  )}>
                    {obj.isInside ? 'IN' : 'OUT'}
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
