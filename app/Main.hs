{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TupleSections #-}

module Main where

import Conduit

import Control.Lens as L
import Control.Monad
import Control.Monad.IO.Class

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC
import qualified Data.Conduit as C
import qualified Data.Conduit.Binary as C
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import qualified Network.AWS as AWS
import Network.AWS.Data.Body
import Network.AWS.Data.Body
import Network.AWS.Data.Crypto
import Network.AWS.Prelude hiding (Base64)
import qualified Network.AWS.S3 as S3

import System.Posix.Files
import System.Posix.Types
import System.IO
import System.Environment
import System.Exit

getFileSize :: FilePath -> IO FileOffset
getFileSize path =
  do
    stat <- getFileStatus path
    return (fileSize stat)

chunkedBody :: (Integral a) => a -> ConduitM () ByteString (ResourceT IO) () -> ChunkedBody
chunkedBody cl src = ChunkedBody defaultChunkSize (fromIntegral cl) src

runAWS :: AWS.Env -> AWS.AWS a -> IO a
runAWS env act = liftIO . AWS.runResourceT $ AWS.runAWS env act

type S3Host = ByteString
type S3Port = Int

awsEnv :: Maybe (S3Host, S3Port) -> IO AWS.Env
awsEnv s3Info = do
    let creds =
          AWS.FromEnv "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" Nothing (Just "AWS_REGION")
        env   = AWS.newEnv creds
    case s3Info of
      Nothing -> env
      Just (s3Host,s3Port) -> do
        let s3 = AWS.setEndpoint False s3Host s3Port S3.s3
        AWS.configure s3 <$> env

err :: IO a
err = do
    hPutStrLn stderr "usage - either of:"
    hPutStrLn stderr "exe-name host <host> <port> <srcFile> <destBucket> <destFile>"
    hPutStrLn stderr "exe-name aws <srcFile> <destBucket> <destFile>"
    exitFailure

main :: IO ()
main = do
    args <- getArgs
    unless (length args > 0) err

    (args', env) <- case args of
             ("aws" : rest) -> (rest,) <$> awsEnv Nothing
             ("host" : s3Host : s3Port : rest) -> (rest,) <$> awsEnv (Just (BSC.pack s3Host, read s3Port))
             _ -> err

    unless (length args' == 3) err
    let [srcFile, destBucket, destPath] = args'
    cl <- getFileSize srcFile
    let src = sourceFile srcFile .| C.isolate (fromIntegral cl)
    fl <- BS.readFile srcFile
    let bdy = chunkedBody cl src
    let md5Res = T.decodeLatin1 $ digestToBase Base64 (hash @_ @MD5 fl)
    let po =
          (S3.putObject
             (S3.BucketName $ T.pack destBucket)
             (S3.ObjectKey $ T.pack destPath)
             (toBody bdy))
    let req = po & S3.poContentMD5 ?~ md5Res
    runAWS env $ (AWS.send req >>= liftIO . print)
