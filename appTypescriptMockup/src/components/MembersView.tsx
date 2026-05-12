import React from 'react';
import { motion } from 'motion/react';
import { 
  Users, 
  UserPlus, 
  Shield, 
  Baby, 
  MoreVertical,
  Mail,
  ShieldAlert
} from 'lucide-react';
import { Card, Button } from './UI';
import { MOCK_USERS } from '../constants';
import { UserRole } from '../types';
import { cn } from '../lib/utils';
import { useSettings, translations } from '../lib/SettingsContext';

export const MembersView: React.FC = () => {
  const { language } = useSettings();
  const t = translations[language];

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold italic">{t.members}</h2>
          <p className="opacity-60">{language === 'it' ? 'Gestisci chi ha accesso alla tua casa e i loro permessi.' : 'Manage family access and permissions.'}</p>
        </div>
        <Button variant="secondary" className="h-10 px-6 rounded-full font-bold">
          <UserPlus className="w-5 h-5 mr-1" />
          {language === 'it' ? 'Invita Membro' : 'Invite Member'}
        </Button>
      </div>

      <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-6">
        {MOCK_USERS.map((user) => (
          <Card key={user.id} variant="solid" className="relative overflow-hidden group border-stormy-teal/10 rounded-[2.5rem]">
            <div className="flex items-start justify-between">
              <div className="flex gap-5">
                <div className="w-16 h-16 rounded-[2rem] bg-gradient-to-br from-stormy-teal to-dark-bg/20 flex items-center justify-center text-white text-2xl font-bold">
                  {user.name[0]}
                </div>
                <div className="space-y-1">
                  <h3 className="text-xl font-bold tracking-tight">{user.name}</h3>
                  <div className="flex items-center gap-2">
                    {user.role === UserRole.ADMIN && <Shield className="w-4 h-4 text-orange-gold" />}
                    {user.role === UserRole.CHILD && <Baby className="w-4 h-4 text-stormy-teal" />}
                    <span className="text-xs font-bold uppercase tracking-widest opacity-40 italic">
                      {user.role}
                    </span>
                  </div>
                </div>
              </div>
              <button className="p-3 hover:bg-stormy-teal/10 rounded-2xl transition-colors shrink-0">
                <MoreVertical className="w-5 h-5 opacity-40" />
              </button>
            </div>

            <div className="mt-6 space-y-4">
              <div className="flex items-center justify-between text-sm">
                <span className="opacity-40 font-bold uppercase text-[10px] tracking-widest">{language === 'it' ? 'Stato attuale' : 'Current Status'}</span>
                <span className={cn(
                  "font-bold px-2 py-0.5 rounded-full text-[10px]",
                  user.isInside ? "text-green-500 bg-green-500/10" : "text-orange-gold bg-orange-gold/10"
                )}>
                  {user.isInside ? (language === 'it' ? 'IN CASA' : 'INSIDE') : (language === 'it' ? 'FUORI' : 'OUTSIDE')}
                </span>
              </div>
              
              <div className="flex items-center justify-between text-sm">
                <span className="opacity-40 font-bold uppercase text-[10px] tracking-widest">{t.lastSeen}</span>
                <span className="font-bold underline decoration-stormy-teal/30">
                  {user.lastSeen ? new Date(user.lastSeen).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '---'}
                </span>
              </div>
            </div>

            <div className="mt-6 flex gap-2">
              <Button variant="ghost" size="sm" className="flex-1 rounded-xl">
                <Mail className="w-4 h-4" /> Log
              </Button>
              <Button variant="ghost" size="sm" className="flex-1 rounded-xl">
                <ShieldAlert className="w-4 h-4" /> Permessi
              </Button>
            </div>
          </Card>
        ))}

        <button className="border-2 border-dashed border-stormy-teal/20 rounded-[2rem] flex flex-col items-center justify-center p-8 opacity-40 hover:opacity-100 hover:border-stormy-teal transition-all gap-4 group">
          <div className="p-4 rounded-3xl bg-stormy-teal/5 group-hover:bg-stormy-teal/20 group-hover:text-stormy-teal transition-all">
            <UserPlus className="w-8 h-8" />
          </div>
          <p className="font-bold uppercase tracking-widest text-[10px]">{language === 'it' ? 'Invita Membro' : 'Invite Member'}</p>
        </button>
      </div>
    </div>
  );
};
