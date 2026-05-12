import React from 'react';
import { motion } from 'motion/react';
import { 
  Package, 
  Trash2, 
  Edit3, 
  Plus,
  Key,
  Briefcase,
  Smartphone,
  Umbrella,
  MoreHorizontal,
  Wifi
} from 'lucide-react';
import { Card, Button } from './UI';
import { MOCK_OBJECTS } from '../constants';
import { cn } from '../lib/utils';
import { useSettings, translations } from '../lib/SettingsContext';

const iconMap = {
  keys: Key,
  bag: Briefcase,
  wallet: Smartphone,
  umbrella: Umbrella,
  other: Package,
};

export const ObjectsView: React.FC = () => {
  const { language } = useSettings();
  const t = translations[language];

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold italic">{t.objects}</h2>
          <p className="opacity-60">{language === 'it' ? 'Controlla quali oggetti sono attualmente in casa o fuori.' : 'Check which objects are currently inside or outside.'}</p>
        </div>
        <Button variant="secondary" className="h-10 px-6 rounded-full font-bold">
          <Plus className="w-5 h-5 mr-1" />
          {t.addTag}
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {MOCK_OBJECTS.map((obj) => {
          const Icon = iconMap[obj.category] || Package;
          return (
            <Card key={obj.id} variant="solid" className="group overflow-hidden border-stormy-teal/10">
              <div className="flex items-center justify-between mb-6">
                <div className={cn(
                  "p-4 rounded-[2rem] transition-colors",
                  obj.isInside ? "bg-stormy-teal text-white" : "bg-orange-gold text-dark-bg"
                )}>
                  <Icon className="w-8 h-8" />
                </div>
                <div className="flex gap-1">
                  <button className="p-2 hover:bg-stormy-teal/10 rounded-2xl transition-colors opacity-40 hover:opacity-100">
                    <Edit3 className="w-4 h-4" />
                  </button>
                  <button className="p-2 hover:bg-red-500/10 rounded-2xl transition-colors opacity-40 hover:opacity-100 text-red-500">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="space-y-1 mb-6">
                <h3 className="text-xl font-bold line-clamp-1 tracking-tight">{obj.name}</h3>
                <div className="flex items-center gap-2 text-xs opacity-40">
                  <Wifi className="w-3 h-3" />
                  <span className="font-mono uppercase font-bold tracking-widest italic">TAG-LINK: {obj.tagId}</span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-4 border-t border-stormy-teal/5">
                <div className="flex flex-col">
                  <span className="text-[10px] opacity-40 uppercase font-black tracking-widest">{language === 'it' ? 'Localizzazione' : 'Location'}</span>
                  <span className={cn(
                    "font-black tracking-tighter text-lg leading-none",
                    obj.isInside ? "text-green-500" : "text-orange-gold"
                  )}>
                    {obj.isInside ? (language === 'it' ? 'PRELEVATO' : 'PICKED UP') : (language === 'it' ? 'FUORI PORTATA' : 'OUT OF REACH')}
                  </span>
                </div>
                
                <Button variant="ghost" size="sm" className="rounded-xl border border-stormy-teal/20 h-9 px-4 font-bold text-[10px] tracking-widest uppercase">
                  LOG
                </Button>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
};
