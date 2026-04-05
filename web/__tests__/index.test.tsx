jest.mock('framer-motion', () => {
    const React = require('react');

    const motion = new Proxy(
        {},
        {
            get: (_, tag: string) =>
                React.forwardRef(
                    (
                        {
                            animate: _animate,
                            children,
                            custom: _custom,
                            exit: _exit,
                            initial: _initial,
                            transition: _transition,
                            variants: _variants,
                            whileHover: _whileHover,
                            whileInView: _whileInView,
                            viewport: _viewport,
                            ...props
                        }: {
                            children?: React.ReactNode;
                        } & Record<string, unknown>,
                        ref: React.Ref<HTMLElement>
                    ) => React.createElement(tag, {ref, ...props}, children)
                ),
        }
    );

    return {
        AnimatePresence: ({children}: { children?: React.ReactNode }) => children,
        motion,
    };
});

jest.mock('@headlessui/react', () => {
    const React = require('react');

    const Dialog = ({
                        children,
                        open,
                    }: {
        children?: React.ReactNode;
        open?: boolean;
    }) => (open ? <div>{children}</div> : null);

    Dialog.Panel = ({
                        children,
                        ...props
                    }: {
        children?: React.ReactNode;
    } & Record<string, unknown>) => <div {...props}>{children}</div>;

    return {Dialog};
});

jest.mock('next/router', () => ({
    useRouter: () => ({
        push: jest.fn(),
        pathname: '/',
        route: '/',
        asPath: '/',
        query: {},
    }),
}));

import {render, screen} from '@testing-library/react';

import Home from '../src/pages/index';
import '@testing-library/jest-dom';

describe('Home', () => {
    it('renders fire-step-web heading', () => {
    render(<Home />);

    const heading = screen.getByRole('heading', {
        name: /пожарной безопасности/i,
    });

    expect(heading).toBeInTheDocument();
  });
});
