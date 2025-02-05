const path = require("path");
const webpack = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const CopyPlugin = require("copy-webpack-plugin");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config();

const isDevelopment = process.env.NODE_ENV !== "production";

module.exports = {
  target: "web",
  mode: isDevelopment ? "development" : "production",
  entry: {
    index: path.join(__dirname, "src", "index.tsx"),
  },
  devtool: isDevelopment ? "source-map" : false,
  optimization: {
    minimize: !isDevelopment,
    minimizer: [new TerserPlugin()],
  },
  resolve: {
    extensions: [".js", ".ts", ".jsx", ".tsx"],
    fallback: {
      assert: require.resolve("assert/"),
      buffer: require.resolve("buffer/"),
      events: require.resolve("events/"),
      stream: require.resolve("stream-browserify/"),
      util: require.resolve("util/"),
    },
    modules: [
      path.resolve(__dirname, "node_modules"),
      path.resolve(__dirname, "../../node_modules"),
    ]
  },
  output: {
    filename: "[name].js",
    path: path.join(__dirname, "dist"),
  },
  module: {
    rules: [
      {
        test: /\.(js|ts)x?$/i,
        exclude: /node_modules/,
        use: {
          loader: "ts-loader",
          options: {
            transpileOnly: true
          }
        },
      },
      {
        test: /\.css$/i,
        use: ["style-loader", "css-loader"],
      }
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, "index.html"),
      cache: false,
      templateParameters: {
        QUIZZY_BACKEND_CANISTER_ID: process.env.CANISTER_ID_QUIZZY_BACKEND || "",
        II_URL: isDevelopment 
          ? `http://localhost:8000?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`
          : "https://identity.ic0.app",
      },
    }),
    new webpack.EnvironmentPlugin({
      NODE_ENV: "development",
      QUIZZY_BACKEND_CANISTER_ID: process.env.CANISTER_ID_QUIZZY_BACKEND || "",
      II_URL: isDevelopment 
        ? `http://localhost:8000?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`
        : "https://identity.ic0.app",
    }),
    new webpack.ProvidePlugin({
      Buffer: [require.resolve("buffer/"), "Buffer"],
      process: require.resolve("process/browser"),
    }),
    new CopyPlugin({
      patterns: [
        {
          from: path.join(__dirname, "assets"),
          to: path.join(__dirname, "dist"),
          noErrorOnMissing: true,
        },
      ],
    }),
  ],
  devServer: {
    proxy: {
      "/api": {
        target: "http://localhost:8000",
        changeOrigin: true,
        pathRewrite: {
          "^/api": "/api",
        },
      },
    },
    hot: true,
    watchFiles: [path.resolve(__dirname, "src")],
    liveReload: true,
  },
}; 