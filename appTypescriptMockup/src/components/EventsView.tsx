import React, { useState } from 'react';
import { useSettings, translations } from '../lib/SettingsContext';
import { Card, Button } from './UI';
import { Search, Calendar, Filter, ChevronDown, Clock, AlertTriangle, ShieldCheck, Tag, User, Download } from 'lucide-react';
import { cn } from '../lib/utils';
import { MOCK_EVENTS } from '../constants';

export const EventsView: React.FC = () => {
  const { language } = useSettings();
  const t = translations[language];
  const [search, setSearch] = useState('');
  const [view, setView] = useState<'day' | 'week' | 'month'>('day');
  const [severityFilter, setSeverityFilter] = useState<'all' | 'critical' | 'info'>('all');

  const filteredEvents = MOCK_EVENTS.filter(e => {
    const message = e.description[language] || '';
    const matchesSearch = message.toLowerCase().includes(search.toLowerCase());
    const matchesSeverity = severityFilter === 'all' || e.severity === severityFilter;
    
    // Simple mock time filtering
    const eventDate = new Date(e.timestamp);
    const now = new Date();
    const diffMs = now.getTime() - eventDate.getTime();
    const diffDays = diffMs / (1000 * 60 * 60 * 24);
    
    let matchesView = true;
    if (view === 'day') matchesView = diffDays <= 1;
    if (view === 'week') matchesView = diffDays <= 7;
    if (view === 'month') matchesView = diffDays <= 30;

    return matchesSearch && matchesSeverity && matchesView;
  });

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex flex-col gap-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-3xl font-black italic tracking-tight">{t.history}</h2>
            <p className="opacity-40 text-sm mt-1 italic">{language === 'it' ? 'Monitora ogni movimento registrato.' : 'Monitor every registered movement.'}</p>
          </div>
          <div className="flex items-center gap-3">
             <div className="flex bg-stormy-teal/5 p-1 rounded-2xl border border-stormy-teal/10">
              {(['day', 'week', 'month'] as const).map(v => (
                <button
                  key={v}
                  onClick={() => setView(v)}
                  className={cn(
                    "px-4 py-2 rounded-xl text-[10px] font-black uppercase transition-all",
                    view === v ? "bg-stormy-teal text-white shadow-lg shadow-stormy-teal/20" : "opacity-30 hover:opacity-100 italic"
                  )}
                >
                  {t[`view${v.charAt(0).toUpperCase() + v.slice(1)}` as keyof typeof t]}
                </button>
              ))}
            </div>
            <Button variant="secondary" className="rounded-full font-black tracking-widest text-[10px] h-10 px-5 shadow-lg shadow-orange-gold/10">
              <Download className="w-4 h-4 mr-2" />
              EXPORT
            </Button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="md:col-span-2 relative">
            <Search className="absolute left-6 top-1/2 -translate-y-1/2 w-4 h-4 opacity-30" />
            <input 
              type="text" 
              placeholder={t.searchEvents}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full h-14 pl-14 pr-6 rounded-[2rem] bg-stormy-teal/5 border border-stormy-teal/10 focus:outline-none focus:border-stormy-teal transition-all font-bold tracking-tight"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-6 top-1/2 -translate-y-1/2 w-4 h-4 opacity-30" />
            <select 
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value as any)}
              className="w-full h-14 pl-14 pr-12 rounded-[2rem] bg-stormy-teal/5 border border-stormy-teal/10 focus:outline-none focus:border-stormy-teal transition-all font-bold appearance-none cursor-pointer tracking-widest uppercase text-[10px] dark:bg-white/5"
            >
              <option value="all" className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">{t.all} Severities</option>
              <option value="critical" className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">{t.critical}</option>
              <option value="info" className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">{t.info}</option>
            </select>
            <ChevronDown className="absolute right-6 top-1/2 -translate-y-1/2 w-4 h-4 opacity-30 pointer-events-none" />
          </div>
          <div className="relative">
            <Calendar className="absolute left-6 top-1/2 -translate-y-1/2 w-4 h-4 opacity-30" />
            <select 
              className="w-full h-14 pl-14 pr-12 rounded-[2rem] bg-stormy-teal/5 border border-stormy-teal/10 focus:outline-none focus:border-stormy-teal transition-all font-bold appearance-none cursor-pointer tracking-widest uppercase text-[10px] dark:bg-white/5"
            >
              <option className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">{language === 'it' ? 'Oggi' : 'Today'}</option>
              <option className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">{language === 'it' ? 'Ieri' : 'Yesterday'}</option>
              <option className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">05 May 2024</option>
              <option className="bg-white text-dark-bg dark:bg-dark-bg dark:text-white">04 May 2024</option>
            </select>
            <ChevronDown className="absolute right-6 top-1/2 -translate-y-1/2 w-4 h-4 opacity-30 pointer-events-none" />
          </div>
        </div>
      </div>

      <Card variant="solid" className="p-0 overflow-hidden border-stormy-teal/10 rounded-[3rem] bento-card">
        <div className="divide-y divide-stormy-teal/5">
          {filteredEvents.map((event) => (
            <div key={event.id} className="p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-stormy-teal/5 transition-all group">
              <div className="flex items-center gap-5">
                <div className={cn(
                  "w-12 h-12 rounded-2xl flex items-center justify-center shrink-0",
                  event.severity === 'critical' ? "bg-orange-gold/10 text-orange-gold" : "bg-stormy-teal/10 text-stormy-teal"
                )}>
                  {event.severity === 'critical' ? <AlertTriangle className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                </div>
                <div>
                  <p className={cn(
                    "font-bold text-base leading-tight tracking-tight",
                    event.severity === 'critical' && "text-orange-gold"
                  )}>
                    {event.description[language]}
                  </p>
                  <div className="flex items-center gap-3 mt-1.5 flex-wrap">
                    <span className="text-[10px] font-black uppercase tracking-widest opacity-30 italic">
                      {new Date(event.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                    <span className="w-1 h-1 bg-stormy-teal/20 rounded-full" />
                    <div className="flex items-center gap-1.5">
                      {event.userId ? <User className="w-3 h-3 opacity-30" /> : <Tag className="w-3 h-3 opacity-30" />}
                      <span className="text-[10px] font-black uppercase tracking-widest text-stormy-teal/60 italic">
                        {event.type}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="flex items-center gap-4 ml-16 sm:ml-0">
                <div className={cn(
                  "p-2 rounded-xl text-[8px] font-black uppercase tracking-[0.2em] italic border shrink-0",
                  event.severity === 'critical' ? "border-orange-gold/20 text-orange-gold bg-orange-gold/5" : "border-stormy-teal/20 text-stormy-teal"
                )}>
                  {event.severity === 'critical' ? 'CRITICAL' : 'SYSTEM'}
                </div>
              </div>
            </div>
          ))}
        </div>
      </Card>

      {filteredEvents.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 opacity-20 italic">
          <Search className="w-16 h-16 mb-4" />
          <p className="font-bold">{language === 'it' ? 'Nessun evento trovato' : 'No events found'}</p>
        </div>
      )}
    </div>
  );
};
