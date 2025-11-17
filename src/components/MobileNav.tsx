import { Link, useLocation } from 'react-router-dom';
import { Home, History, Beaker, Settings } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { path: '/home', label: 'Today', icon: Home },
  { path: '/history', label: 'History', icon: History },
  { path: '/labs', label: 'Labs', icon: Beaker },
  { path: '/settings', label: 'Settings', icon: Settings },
];

export function MobileNav() {
  const location = useLocation();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-surface border-t border-border safe-area-inset-bottom">
      <div className="flex items-center justify-around h-20 max-w-lg mx-auto px-safe">
        {navItems.map(({ path, label, icon: Icon }) => {
          const isActive = location.pathname === path;
          return (
            <Link
              key={path}
              to={path}
              className={cn(
                "flex flex-col items-center justify-center flex-1 h-full gap-1.5 transition-colors min-w-[44px]",
                isActive
                  ? "text-primary"
                  : "text-muted hover:text-foreground"
              )}
            >
              <Icon className={cn("h-6 w-6", isActive && "scale-105")} strokeWidth={isActive ? 2.5 : 2} />
              <span className="text-[10px] font-medium leading-tight">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
