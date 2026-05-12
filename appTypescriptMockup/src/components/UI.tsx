import React from 'react';
import { motion, HTMLMotionProps } from 'motion/react';
import { cn } from '../lib/utils'; // I'll create this utility next

interface CardProps extends HTMLMotionProps<'div'> {
  children: React.ReactNode;
  className?: string;
  variant?: 'glass' | 'solid' | 'outline';
}

export const Card: React.FC<CardProps> = ({ 
  children, 
  className, 
  variant = 'glass',
  ...props 
}) => {
  const variants = {
    glass: 'glass rounded-3xl p-6',
    solid: 'bento-card p-6',
    outline: 'border border-stormy-teal/20 rounded-3xl p-6'
  };

  return (
    <motion.div
      className={cn(variants[variant], className)}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      {...props}
    >
      {children}
    </motion.div>
  );
};

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  className?: string;
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

export const Button: React.FC<ButtonProps> = ({
  children,
  className,
  variant = 'primary',
  size = 'md',
  ...props
}) => {
  const variants = {
    primary: 'bg-stormy-teal text-white hover:opacity-90',
    secondary: 'bg-orange-gold text-dark-bg hover:opacity-90',
    ghost: 'bg-transparent hover:bg-stormy-teal/10 transition-colors'
  };

  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-lg'
  };

  return (
    <button
      className={cn(
        'rounded-2xl font-bold transition-all active:scale-95 disabled:opacity-50 disabled:pointer-events-none flex items-center justify-center gap-2 cursor-pointer',
        variants[variant],
        sizes[size],
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
};
