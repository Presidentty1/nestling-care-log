import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'app.lovable.3be850d6430e4062887da465d2abf643',
  appName: 'nestling-care-log',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    // For development hot-reload (uncomment and set your local IP):
    // url: 'http://192.168.1.10:5173',
    // cleartext: true
  },
  plugins: {
    LocalNotifications: {
      smallIcon: "ic_stat_icon_config_sample",
      iconColor: "#488AFF",
      sound: "beep.wav",
    },
    Haptics: {
      enabled: true
    },
    LocalNotifications: {
      smallIcon: "ic_stat_icon_config_sample",
      iconColor: "#488AFF",
      sound: "beep.wav",
      actions: [
        {
          id: 'FEED_ACTIONS',
          actions: [
            { id: 'log-feed', title: 'Log Feed', foreground: true },
            { id: 'dismiss', title: 'Dismiss', destructive: false }
          ]
        },
        {
          id: 'NAP_ACTIONS',
          actions: [
            { id: 'log-nap', title: 'Log Nap', foreground: true },
            { id: 'dismiss', title: 'Dismiss', destructive: false }
          ]
        },
        {
          id: 'DIAPER_ACTIONS',
          actions: [
            { id: 'log-diaper', title: 'Log Diaper', foreground: true },
            { id: 'dismiss', title: 'Dismiss', destructive: false }
          ]
        }
      ]
    }
  }
};

export default config;
