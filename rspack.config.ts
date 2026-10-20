import * as path from 'node:path';
import { CopyRspackPlugin } from '@rspack/core';
import { defineConfig } from '@rspack/cli';
import { ConsoleRemotePlugin } from '@openshift-console/dynamic-plugin-sdk-webpack';
import { TsCheckerRspackPlugin } from 'ts-checker-rspack-plugin';
import { consolePlugin as consolePluginMetadata } from './package.json';

const isProd = process.env.NODE_ENV === 'production';

export default defineConfig({
  mode: isProd ? 'production' : 'development',
  // No regular entry points needed. All plugin related scripts are generated via ConsoleRemotePlugin.
  entry: {},
  context: path.resolve(import.meta.dirname, 'src'),
  output: {
    path: path.resolve(import.meta.dirname, 'dist'),
    filename: isProd ? '[name]-bundle-[hash].min.js' : '[name]-bundle.js',
    chunkFilename: isProd ? '[name]-chunk-[chunkhash].min.js' : '[name]-chunk.js',
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js'],
  },
  module: {
    parser: {
      'css/auto': {
        namedExports: false,
      },
    },
    generator: {
      'css/auto': {
        localIdentName: `${consolePluginMetadata.name}__[local]--[hash:base64:6]`,
      },
    },
    rules: [
      {
        test: /\.(js|tsx?)$/,
        exclude: /\/node_modules\//,
        use: {
          loader: 'builtin:swc-loader',
          options: {
            detectSyntax: 'auto',
            jsc: {
              transform: {
                react: {
                  runtime: 'automatic'
                },
                reactCompiler: {
                  target: '18',
                },
              },
              target: 'es2021',
            },
          },
        },
        type: 'javascript/auto',
      },
      {
        test: /\.css$/,
        use: 'builtin:lightningcss-loader',
        type: 'css/auto',
      },
      {
        test: /\.(png|jpg|jpeg|gif|svg)(\?.*$|$)/,
        type: 'asset/resource',
        generator: {
          filename: isProd ? 'assets/[contenthash][ext]' : 'assets/[name][ext]',
        },
      },
    ],
  },
  devServer: {
    static: './dist',
    port: 9001,
    // Allow Bridge running in a container to connect to the plugin dev server.
    allowedHosts: 'all',
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'X-Requested-With, Content-Type, Authorization',
    },
    devMiddleware: {
      writeToDisk: true,
    },
  },
  plugins: [
    new ConsoleRemotePlugin(),
    new TsCheckerRspackPlugin({
      typescript: {
        configFile: path.resolve(import.meta.dirname, 'tsconfig.json'),
      },
    }),
    new CopyRspackPlugin({
      patterns: [{ from: path.resolve(import.meta.dirname, 'locales'), to: 'locales' }],
    }),
  ],
  devtool: isProd ? false : 'source-map',
});
