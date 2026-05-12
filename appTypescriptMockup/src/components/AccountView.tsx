import React from 'react';
import { useSettings, translations } from '../lib/SettingsContext';
import { Card, Button } from './UI';
import { User, Shield, LogOut, Mail, Phone, Calendar, Key } from 'lucide-react';
import { cn } from '../lib/utils';

export const AccountView: React.FC = () => {
  const { language, theme } = useSettings();
  const t = translations[language];

  const profileData = {
    name: 'Marco Rossi',
    email: 'marco.rossi@fastwebnet.it',
    phone: '+39 333 4567890',
    joined: '12 Gen 2024',
    role: 'Admin / Capofamiglia'
  };

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex flex-col md:flex-row gap-8 items-start">
        <div className="w-full md:w-1/3 flex flex-col items-center gap-6">
          <div className="relative group">
            <div className="w-40 h-40 rounded-[3.5rem] bg-gradient-to-br from-stormy-teal to-charcoal-blue flex items-center justify-center text-white text-6xl font-black italic shadow-2xl shadow-stormy-teal/20 transition-transform group-hover:scale-105 duration-300">
              M
            </div>
            <div className="absolute -bottom-2 -right-2 bg-orange-gold text-dark-bg p-3 rounded-[1.5rem] shadow-xl">
              <Shield className="w-6 h-6" />
            </div>
          </div>
          
          <div className="text-center">
            <h2 className="text-3xl font-black italic tracking-tight">{profileData.name}</h2>
            <p className="opacity-40 font-bold uppercase tracking-widest text-[10px] mt-1">{profileData.role}</p>
          </div>

          <Button variant="outline" className="w-full rounded-3xl border-red-500/20 text-red-500 hover:bg-red-500/10 h-14 font-black tracking-widest">
            <LogOut className="w-5 h-5 mr-3" />
            {t.logout}
          </Button>
        </div>

        <div className="flex-1 w-full space-y-6">
          <Card variant="solid" className="p-8 border-stormy-teal/10 rounded-[3rem]">
            <h3 className="text-xl font-black italic mb-8 uppercase tracking-widest opacity-40">{t.profileInfo}</h3>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-8">
              <div className="space-y-2">
                <label className="text-[10px] font-black uppercase tracking-widest opacity-30 flex items-center gap-2">
                  <Mail className="w-3 h-3" /> Email
                </label>
                <p className="font-bold text-lg">{profileData.email}</p>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black uppercase tracking-widest opacity-30 flex items-center gap-2">
                  <Phone className="w-3 h-3" /> {language === 'it' ? 'Telefono' : 'Phone'}
                </label>
                <p className="font-bold text-lg">{profileData.phone}</p>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black uppercase tracking-widest opacity-30 flex items-center gap-2">
                  <Calendar className="w-3 h-3" /> {language === 'it' ? 'Membro dal' : 'Joined'}
                </label>
                <p className="font-bold text-lg">{profileData.joined}</p>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black uppercase tracking-widest opacity-30 flex items-center gap-2">
                  <Key className="w-3 h-3" /> {t.securitySettings}
                </label>
                <p className="font-bold text-lg">{t.mfaActive}</p>
              </div>
            </div>
          </Card>

          <Card variant="solid" className="p-8 border-stormy-teal/10 rounded-[3rem] bg-stormy-teal/5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-black italic uppercase tracking-widest opacity-40">{t.activeSessions}</h3>
              <span className="bg-green-500/10 text-green-500 text-[10px] font-black px-3 py-1 rounded-full">LIVE</span>
            </div>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 rounded-2xl bg-white/5 border border-white/5">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-xl bg-stormy-teal/10 flex items-center justify-center">
                    <User className="w-5 h-5 text-stormy-teal" />
                  </div>
                  <div>
                    <p className="font-bold text-sm">Chrome su Raspberry Pi Hub</p>
                    <p className="text-[10px] opacity-40 italic">Milano, Italia • {t.onlineNow}</p>
                  </div>
                </div>
                <Button variant="ghost" size="sm" className="text-[10px] font-black uppercase tracking-widest opacity-40 hover:opacity-100">{t.close}</Button>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};
