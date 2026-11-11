import React from 'react';
import {Composition, AbsoluteFill} from 'remotion';
import {FontLoader} from './kit/Fonts';
import {Ad1Tonight} from './ads/Ad1Tonight';
import {Ad2Unsent} from './ads/Ad2Unsent';
import {Ad3OneDrop} from './ads/Ad3OneDrop';
import {Ad4TooLoud} from './ads/Ad4TooLoud';
import {Ad5Year} from './ads/Ad5Year';

const Wrapper: React.FC<{children: React.ReactNode}> = ({children}) => (
  <AbsoluteFill>
    <FontLoader />
    {children}
  </AbsoluteFill>
);

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="Ad1Tonight"
      component={() => <Wrapper><Ad1Tonight /></Wrapper>}
      durationInFrames={560}
      fps={30}
      width={1080}
      height={1920}
    />
    <Composition
      id="Ad2Unsent"
      component={() => <Wrapper><Ad2Unsent /></Wrapper>}
      durationInFrames={560}
      fps={30}
      width={1080}
      height={1920}
    />
    <Composition
      id="Ad3OneDrop"
      component={() => <Wrapper><Ad3OneDrop /></Wrapper>}
      durationInFrames={560}
      fps={30}
      width={1080}
      height={1920}
    />
    <Composition
      id="Ad4TooLoud"
      component={() => <Wrapper><Ad4TooLoud /></Wrapper>}
      durationInFrames={450}
      fps={30}
      width={1080}
      height={1920}
    />
    <Composition
      id="Ad5Year"
      component={() => <Wrapper><Ad5Year /></Wrapper>}
      durationInFrames={560}
      fps={30}
      width={1080}
      height={1920}
    />
  </>
);
