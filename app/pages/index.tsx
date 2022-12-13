import React, { useState, useEffect } from "react";

import type { NextPage } from "next";
import Head from "next/head";

import axios from "axios";
import { Tensor, InferenceSession } from "onnxjs";
import { ToastContainer, toast } from "react-toastify";
import Webcam from "react-webcam";

import Address from "../components/Address";
import ClassifyResult from "../components/ClassifyResult";
import Footer from "../components/Footer";

import {
  getEthereumObject,
  setupEthereumEventListeners,
  getSignedContract,
  getCurrentAccount,
  connectWallet,
} from "../utils/ethereum";

import { buildContractCallArgs, generateProof } from "../utils/snark";
import { computeQuantizedEmbedding } from "../utils/model";

import metadata from "../data/Verifier.json";

import "react-toastify/dist/ReactToastify.css";

const videoConstraints = {
  width: 1280,
  height: 720,
  facingMode: "user",
};

const VERIFIER_CONTRACT_ADDR = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const VERIFIER_CONTRACT_ABI: any = metadata.abi;

const mlModelUrl = "/frontend_model.onnx";

const title = "ZK Face Recognition";
const description =
  "Recognizing faces privately using ZK Snarks and Machine Learning";

const appHeading = "ZK Face Recognition";
const appDescription =
  "In this app, we use ZK Snarks and Machine Learning to recognize a face privately";

const primaryButtonClasses =
  "text-white bg-blue-500 hover:bg-blue-700 font-bold px-4 py-2 rounded-full shadow-lg disabled:opacity-50";

const Home: NextPage = () => {
  const [isModelLoaded, setIsModelLoaded] = useState(false);
  const [session, setSession] = useState<any>();

  const [account, setAccount] = useState();
  const [verifierContract, setVerifierContract] = useState<any>();

  const [prediction, setPrediction] = useState<null | number>();
  const [publicSignals, setPublicSignals] = useState<number[]>();
  const [proof, setProof] = useState<any>();

  const [selectedImage, setSelectedImage] = useState<any>();

  const [image, setImage] = useState(null);

  const videoConstraints = {
    width: 1280,
    height: 720,
    facingMode: "user",
  };

  const preProcess = async (fileInput: any): Promise<Tensor | null> => {
    let tensorData;
    try {
      if (!fileInput) return null;

      const formData = new FormData();
      formData.append("file", fileInput);

      const response = await axios.post(
        "http://localhost:8000/embeddings",
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        }
      );

      tensorData = response.data?.embeddings;
    } catch (e) {
      console.log("preProcess error: ", e);
    }

    const tensor = new Tensor(new Float32Array(512), "float32", [1, 512]);
    (tensor.data as Float32Array).set(tensorData);
    return tensor;
  };

  const runModel = async (
    model: InferenceSession,
    preProcessedData: Tensor
  ): Promise<[Tensor, number]> => {
    const start = new Date();
    try {
      const outputData = await model.run([preProcessedData]);
      const end = new Date();
      const inferenceTime = end.getTime() - start.getTime();
      const output = outputData.values().next().value;
      return [output, inferenceTime];
    } catch (e) {
      console.error(e);
      throw new Error();
    }
  };

  const classifyAndGenerateProof = async (base64Image: any, session: any) => {
    if (!session) return;

    try {
      const result = await fetch(base64Image);
      const blob = await result.blob();

      const file = new File([blob], "filename.jpeg");

      const preProcessedData = await preProcess(file);
      if (!preProcessedData) return;

      let [modelOutput, _] = await runModel(session, preProcessedData);

      var output = modelOutput.data;
      const quantizedEmbedding = computeQuantizedEmbedding(output, 1);

      const { proof, publicSignals } = await generateProof(quantizedEmbedding);
      const maxValue = Math.max(...publicSignals);

      setPublicSignals(publicSignals);
      setPrediction(maxValue);
      setProof(proof);

      toast.success(
        "Face classification and proof generation completed successfully"
      );
    } catch (e) {
      console.warn(e);
    }
  };

  const verifyProof = async (proof: any, publicSignals: any) => {
    //@ts-ignore
    if (!window?.ethereum || !account) {
      toast.error("Please connect your MetaMask walet");
      return;
    }

    const callArgs = await buildContractCallArgs(proof, publicSignals);
    const result = await verifierContract.verifyProof(...callArgs);

    if (result) {
      toast.success("Proof successfully validated on chain");
      return;
    }
    toast.error("Proof was incorrect");
  };

  const onImageChange = async (e: any) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedImage(URL.createObjectURL(e.target.files[0]));
    }
  };

  const setupWallet = async () => {
    const ethereum = getEthereumObject();
    if (!ethereum) return;

    setupEthereumEventListeners(ethereum);

    const verifierContract = getSignedContract(
      VERIFIER_CONTRACT_ADDR,
      VERIFIER_CONTRACT_ABI
    );

    if (!verifierContract) return;

    const currentAccount = await getCurrentAccount();
    setVerifierContract(verifierContract);
    setAccount(currentAccount);
  };

  const loadModel = async () => {
    const session = new InferenceSession({ backendHint: "cpu" });
    const url = mlModelUrl;
    await session.loadModel(url);

    setIsModelLoaded(true);
    setSession(session);
  };

  useEffect(() => {
    setupWallet();
    loadModel();
  }, []);

  const isImageLoaded = Boolean(selectedImage);
  const isImageAndProofPresent = isImageLoaded && Boolean(proof);

  const isMetamaskConnected = !!account;

  const webcamRef = React.useRef(null);
  const capture = React.useCallback(() => {
    //@ts-ignore
    const imageSrc = webcamRef?.current.getScreenshot();
    setImage(imageSrc);
  }, [webcamRef]);

  useEffect(() => {
    if (!image || !session) return;
    classifyAndGenerateProof(image, session);
  }, [image, session]);

  return (
    <div className="min-h-screen items-center py-2">
      <Head>
        <title>ZK Face Recognition</title>
        <meta property="og:type" content="website" />
        <meta property="og:title" content={title} />
        <meta property="og:description" content={description} />
        <meta
          property="og:image"
          content="https://ethereum-bootcamp-frontend.vercel.app/og-image.png"
        />
        <link rel="icon" href="/favicon.png" />
      </Head>
      <ToastContainer position="bottom-center" autoClose={1500} closeOnClick />

      <div className="my-4 text-center block ">
        {!isMetamaskConnected && (
          <button
            className="mx-auto mt-4 inline-flex items-center rounded border-0 bg-gray-100 py-1 px-3 text-base hover:bg-gray-200 focus:outline-none md:mt-0"
            onClick={connectWallet}
          >
            Connect Wallet
          </button>
        )}
        {isMetamaskConnected && (
          <div className="flex gap-2 mx-auto w-min">
            <Address address={account} />
          </div>
        )}
      </div>

      <main className="flex w-full flex-1 flex-col items-center px-20 pt-12 text-center">
        <h1 className="text-6xl font-bold">
          Welcome to{" "}
          <a className="text-blue-600" href="https://nextjs.org">
            {appHeading}
          </a>
        </h1>

        <p className="mt-3 text-2xl">{appDescription}</p>

        <div className="my-2">
          {/* <WebcamCapture setImage={setImage} /> */}
          <Webcam
            audio={false}
            height={720}
            ref={webcamRef}
            screenshotFormat="image/jpeg"
            width={1280}
            videoConstraints={videoConstraints}
            className="w-6/12 mx-auto"
          />
          {/* <button onClick={capture}>Capture photo</button> */}
        </div>

        <div className="my-12 mt-6">
          {!isModelLoaded && <p>Loading model ...</p>}

          {isModelLoaded && (
            <div className="flex flex-col gap-8 items-center">
              <div className="flex gap-2 mt-4">
                <div>
                  <button
                    className={primaryButtonClasses}
                    // onClick={() => classifyAndGenerateProof(image, session)}
                    onClick={capture}
                    // disabled={!image}
                  >
                    Classify and Generate Proof
                  </button>
                </div>
                <div>
                  <button
                    className={primaryButtonClasses}
                    onClick={() => verifyProof(proof, publicSignals)}
                    disabled={!Boolean(proof)}
                  >
                    Verify Proof on chain
                  </button>
                </div>
              </div>
              {prediction !== null && prediction !== undefined && (
                <ClassifyResult prediction={prediction} proof={proof} />
              )}
            </div>
          )}
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Home;
