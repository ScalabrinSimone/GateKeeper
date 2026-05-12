import React from 'react';
import { useSettings, translations } from '../lib/SettingsContext';
import { Card, Button } from './UI';
import { Bell, AlertTriangle, Info, Package, MoreHorizontal, CheckCircle } from 'lucide-react';
import { cn } from '../lib/utils';
import { MOCK_EVENTS } from '../constants';

export const NotificationsView: React.FC = () => {
  const { language } = useSettings();
  const t = translations[language];

  const notifications = MOCK_EVENTS.filter(e => e.severity === 'critical' || e.type.includes('tag'));

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-black italic tracking-tight">{t.notifications}</h2>
          <p className="opacity-40 text-sm mt-1 italic">{language === 'it' ? 'Resta aggiornato sugli eventi critici.' : 'Stay updated on critical events.'}</p>
        </div>
        <Button variant="ghost" size="sm" className="rounded-full border border-stormy-teal/20 text-[10px] font-black tracking-widest uppercase">
          <CheckCircle className="w-4 h-4 mr-2" />
          {t.markAsRead}
        </Button>
      </div>

      <div className="space-y-3">
        {notifications.map((notif) => (
          <Card key={notif.id} variant="solid" className={cn(
            "p-6 flex items-center justify-between border-stormy-teal/10 rounded-[2.5rem] group transition-all hover:bg-stormy-teal/5",
            notif.severity === 'critical' && "border-orange-gold/20 bg-orange-gold/5"
          )}>
            <div className="flex items-center gap-6">
              <div className={cn(
                "w-14 h-14 rounded-[1.5rem] flex items-center justify-center",
                notif.severity === 'critical' ? "bg-orange-gold text-dark-bg" : "bg-stormy-teal/10 text-stormy-teal"
              )}>
                {notif.severity === 'critical' ? <AlertTriangle className="w-7 h-7" /> : <Info className="w-7 h-7" />}
              </div>
              <div>
                <p className="font-bold text-lg tracking-tight">{notif.description[language]}</p>
                <div className="flex items-center gap-3 mt-1">
                  <span className="text-[10px] font-black uppercase tracking-widest opacity-40 italic">
                    {new Date(notif.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                  <span className="w-1 h-1 bg-stormy-teal/20 rounded-full" />
                  <span className="text-[10px] font-black uppercase tracking-widest text-stormy-teal italic">
                    {notif.type}
                  </span>
                </div>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" className="rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                <MoreHorizontal className="w-5 h-5 opacity-40" />
              </Button>
            </div>
          </Card>
        ))}
      </div>

      {notifications.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 opacity-20 italic">
          <Bell className="w-16 h-16 mb-4" />
          <p className="font-bold">{t.noNotifications}</p>
        </div>
      )}
    </div>
  );
};
