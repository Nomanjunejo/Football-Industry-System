/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        pitch: {
          50: '#f0fdf4',
          100: '#dcfce7',
          600: '#16803c',
          700: '#116530',
          800: '#0d4f26',
          900: '#0a3d1e',
        },
      },
    },
  },
  plugins: [],
}
