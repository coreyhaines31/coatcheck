import {loadFont} from '@remotion/google-fonts/Inter';
import {loadFont as loadDisplay} from '@remotion/google-fonts/BarlowSemiCondensed';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {MenuBarScene} from './MenuBarScene';

// Inter stands in for SF Pro when rendering off a Mac; Barlow Semi Condensed is the family's display face.
loadFont('normal', {weights: ['500', '600', '700'], subsets: ['latin']});
loadDisplay('normal', {weights: ['300', '600', '700'], subsets: ['latin']});

export type OgVideoProps = {
  name: string;
  icon: string;
  headline: string;
  headlineAccent: string;
  sub: string;
  accent: string;
};

export const FONT = '-apple-system, BlinkMacSystemFont, "SF Pro Display", Inter, system-ui, sans-serif';
export const DISPLAY = '"Barlow Semi Condensed", "Helvetica Neue", system-ui, sans-serif';
export const INK = '#161616';
export const INK_2 = '#3d3f41';

const BRUSH = 'repeating-linear-gradient(0deg, rgba(255,255,255,.22) 0 1px, rgba(0,0,0,.035) 1px 2px, transparent 2px 3px), repeating-linear-gradient(0deg, rgba(0,0,0,.035) 0 1px, transparent 1px 7px), linear-gradient(100deg, rgba(255,255,255,0) 18%, rgba(255,255,255,.5) 40%, rgba(255,255,255,0) 64%), linear-gradient(180deg, #e7e8e9, #c3c5c7)';

// The Brushed family shell: brushed aluminium, a black nameplate with the app's pilot light, a Barlow headline.
// Coat Check uses the wide arrangement: brand and headline across the top, and a full-width menu bar scene below,
// since the notch only reads in a whole menu bar. Colour appears only in the pilot light.
export const OgVideo = (props: OgVideoProps) => (
  <AbsoluteFill style={{background: BRUSH, color: INK, fontFamily: FONT, WebkitFontSmoothing: 'antialiased'}}>
    <div style={{position: 'absolute', left: 100, right: 100, top: 56, display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 16, fontFamily: DISPLAY, fontSize: 38, fontWeight: 700}}>
        <Img src={staticFile(props.icon)} style={{width: 64, height: 64}} />
        {props.name}
      </div>
      <div style={{display: 'flex', alignItems: 'center', gap: 12, fontFamily: DISPLAY, fontSize: 17, fontWeight: 600, letterSpacing: '0.24em', textTransform: 'uppercase',
        background: '#1b1b1b', color: '#d8d9da', padding: '9px 16px 9px 13px', borderRadius: 2}}>
        <span style={{width: 9, height: 9, borderRadius: '50%', background: props.accent, boxShadow: `0 0 7px ${props.accent}`}} />
        {props.sub}
      </div>
    </div>
    <div style={{position: 'absolute', left: 100, right: 100, top: 142, fontFamily: DISPLAY, fontSize: 64, lineHeight: 0.98, fontWeight: 600}}>
      {props.headline}
      <br />
      <span style={{fontWeight: 300}}>{props.headlineAccent}</span>
    </div>
    <div style={{position: 'absolute', left: 100, top: 318, width: 1000, height: 256}}>
      <MenuBarScene accent={props.accent} />
    </div>
  </AbsoluteFill>
);
