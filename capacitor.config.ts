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
    }
  }
};

export default config;
