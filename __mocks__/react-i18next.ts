import type { FC, PropsWithChildren } from 'react';

export const useTranslation = () => ({ t: (key: string) => key });

export const Trans: FC<PropsWithChildren> = ({ children }) => children;
