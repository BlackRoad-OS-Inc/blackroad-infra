#!/usr/bin/env python3
"""
RoadChain Model Verification — SHA-2048 identity for every AI model on the system.

Scans macOS for Apple AI models (.mlmodelc) and frameworks, computes
SHA-2048 fingerprints, and registers them on-chain.

identity > provider — the model's hash IS the model.

Usage:
    python3 roadchain-verify-models.py          # Full scan + register
    python3 roadchain-verify-models.py --stats   # Show stats
    python3 roadchain-verify-models.py --list     # List all verified models
    python3 roadchain-verify-models.py --verify   # Re-verify all models

BlackRoad OS, Inc. 2026
"""

import sys
import time
from pathlib import Path

from roadchain.identity.model_registry import ModelRegistry

# ── Colors ────────────────────────────────────────────────────────────
PINK = "\033[38;5;205m"
AMBER = "\033[38;5;214m"
BLUE = "\033[38;5;69m"
VIOLET = "\033[38;5;135m"
GREEN = "\033[38;5;82m"
WHITE = "\033[1;37m"
DIM = "\033[2m"
RED = "\033[38;5;196m"
RESET = "\033[0m"


# ══════════════════════════════════════════════════════════════════════
# APPLE AI MODELS — CoreML compiled models (.mlmodelc)
# ══════════════════════════════════════════════════════════════════════

APPLE_MODELS = [
    # ── Body Pose Detection ──
    ("2DHumanPoseDetectorFull", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/2DHumanPoseDetectorFull.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("2DHumanPoseDetectorFull_H13", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/H13/2DHumanPoseDetectorFull_H13.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("2DHumanPoseDetectorFull_H14", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/H14/2DHumanPoseDetectorFull_H14.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("2DHumanPoseDetectorFull_H15", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/H15/2DHumanPoseDetectorFull_H15.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("3DHumanPoseLiftingSequenceFirstStage", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/3DHumanPoseLiftingSequenceFirstStage.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("3DHumanPoseLiftingSequenceFirstStage_H13", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/H13/3DHumanPoseLiftingSequenceFirstStage_H13.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("3DHumanPoseLiftingSequenceFirstStage_H14", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/H14/3DHumanPoseLiftingSequenceFirstStage_H14.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),
    ("3DHumanPoseLiftingSequenceFirstStage_H15", "/System/Library/PrivateFrameworks/AltruisticBodyPoseKit.framework/H15/3DHumanPoseLiftingSequenceFirstStage_H15.mlmodelc", "pose-detection", "AltruisticBodyPoseKit"),

    # ── Voice / Speech ──
    ("AcousticLID", "/System/Library/PrivateFrameworks/CoreSpeech.framework/Resources/AcousticLID.mlmodelc", "speech", "CoreSpeech"),
    ("AutoG2P8B", "/System/Library/PrivateFrameworks/VoiceActions.framework/Versions/A/Resources/AutoG2P8B.mlmodelc", "speech", "VoiceActions"),

    # ── Nearby Interaction / Antenna ──
    ("AntennaMask_1_NN_V5_Model_DeviceType_201", "/System/Library/NearbyInteractionBundles/BiasEstimatorResourceBundle.bundle/Contents/Resources/AntennaMask_1_NN_V5_Model_DeviceType_201.mlmodelc", "spatial", "NearbyInteraction"),
    ("AntennaMask_1_NN_V5_ScalingModel_DeviceType_201", "/System/Library/NearbyInteractionBundles/BiasEstimatorResourceBundle.bundle/Contents/Resources/AntennaMask_1_NN_V5_ScalingModel_DeviceType_201.mlmodelc", "spatial", "NearbyInteraction"),
    ("AntennaMask_2_NN_V5_Model_DeviceType_201", "/System/Library/NearbyInteractionBundles/BiasEstimatorResourceBundle.bundle/Contents/Resources/AntennaMask_2_NN_V5_Model_DeviceType_201.mlmodelc", "spatial", "NearbyInteraction"),
    ("AntennaMask_2_NN_V5_ScalingModel_DeviceType_201", "/System/Library/NearbyInteractionBundles/BiasEstimatorResourceBundle.bundle/Contents/Resources/AntennaMask_2_NN_V5_ScalingModel_DeviceType_201.mlmodelc", "spatial", "NearbyInteraction"),

    # ── Messaging / Contacts ──
    ("AutoSendModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/AutoSendModel.mlmodelc", "suggestions", "CoreSuggestions"),
    ("AutoSendPrivateNoOp", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/AutoSendPrivateNoOp.mlmodelc", "suggestions", "CoreSuggestions"),
    ("ContactRanker", "/System/Library/PrivateFrameworks/PeopleSuggester.framework/Versions/A/Resources/ContactRanker.mlmodelc", "contacts", "PeopleSuggester"),
    ("ContactRankerModel", "/System/Library/PrivateFrameworks/PeopleSuggester.framework/Versions/A/Resources/ContactRankerModel.mlmodelc", "contacts", "PeopleSuggester"),
    ("ContactRanker_watchos_ios_baxter", "/System/Library/PrivateFrameworks/PeopleSuggester.framework/Versions/A/Resources/ContactRanker_watchos_ios_baxter.mlmodelc", "contacts", "PeopleSuggester"),
    ("MentionGenerationModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/MentionGenerationModel.mlmodelc", "nlp", "CoreSuggestions"),
    ("MessageAppPredictorPeopleCentric", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/MessageAppPredictorPeopleCentric.mlmodelc", "suggestions", "CoreSuggestions"),
    ("MDNameToEmailPersonLinker", "/System/Library/PrivateFrameworks/PeopleSuggester.framework/Versions/A/Resources/MDNameToEmailPersonLinker.mlmodelc", "contacts", "PeopleSuggester"),
    ("MDNameToNamePersonLinker", "/System/Library/PrivateFrameworks/PeopleSuggester.framework/Versions/A/Resources/MDNameToNamePersonLinker.mlmodelc", "contacts", "PeopleSuggester"),

    # ── Dining / Maps ──
    ("DiningOutModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/DiningOutModel.mlmodelc", "suggestions", "CoreSuggestions"),
    ("MapsSuggestionsTransportModePrediction", "/System/Library/CoreServices/MapsSuggestionsTransportModePrediction.mlmodelc", "maps", "MapsSuggestions"),

    # ── NLP / Entity ──
    ("EEPmodel_Dictation_v1_hallucination_1", "/System/Library/PrivateFrameworks/CoreSpeech.framework/Resources/EEPmodel_Dictation_v1_hallucination_1.mlmodelc", "speech", "CoreSpeech"),
    ("EEPmodel_v8_hallucination_1", "/System/Library/PrivateFrameworks/CoreSpeech.framework/Resources/EEPmodel_v8_hallucination_1.mlmodelc", "speech", "CoreSpeech"),
    ("EntityRelevanceModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/EntityRelevanceModel.mlmodelc", "nlp", "CoreSuggestions"),
    ("EntityRerankerModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/EntityRerankerModel.mlmodelc", "nlp", "CoreSuggestions"),
    ("EntityTagging_Family", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/EntityTagging_Family.mlmodelc", "nlp", "CoreSuggestions"),
    ("EntityTagging_FamilyAndFriends", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/EntityTagging_FamilyAndFriends.mlmodelc", "nlp", "CoreSuggestions"),
    ("PPModel_NE_Filtering", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/PPModel_NE_Filtering.mlmodelc", "nlp", "CoreSuggestions"),
    ("PSC", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/PSC.mlmodelc", "nlp", "CoreSuggestions"),

    # ── Vision / Image ──
    ("ETShadowModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/ETShadowModel.mlmodelc", "vision", "CoreSuggestions"),
    ("ImageClassifier", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/ImageClassifier.mlmodelc", "vision", "CoreSuggestions"),
    ("Image_Estimator_HEIF", "/System/iOSSupport/System/Library/PrivateFrameworks/IMTranscoderAgent.framework/Versions/A/Resources/Image_Estimator_HEIF.mlmodelc", "vision", "IMTranscoderAgent"),
    ("MonzaV4_1", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/MonzaV4_1.mlmodelc", "vision", "CoreSuggestions"),

    # ── Search / Ranking ──
    ("FCUserVectorModel", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/FCUserVectorModel.mlmodelc", "search", "CoreSuggestions"),
    ("L2XGBRegressor", "/System/Library/PrivateFrameworks/SpotlightServices.framework/Versions/A/Resources/L2XGBRegressor.mlmodelc", "search", "SpotlightServices"),
    ("LOITypeToOneHotTransformer", "/System/Library/PrivateFrameworks/CoreSuggestions.framework/Resources/LOITypeToOneHotTransformer.mlmodelc", "search", "CoreSuggestions"),

    # ── Sound Analysis ──
    ("SNAudioQualityModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNAudioQualityModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNSoundPrintAEmbeddingModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNSoundPrintAEmbeddingModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNSoundPrintKEmbeddingModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNSoundPrintKEmbeddingModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishBabbleModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishBabbleModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishCheeringModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishCheeringModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishEmbeddingModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishEmbeddingModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishFireAlarmModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishFireAlarmModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishLaughterModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishLaughterModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishMusicModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishMusicModel.mlmodelc", "audio", "SoundAnalysis"),
    ("SNVGGishSpeechModel", "/System/Library/Frameworks/SoundAnalysis.framework/Versions/A/Resources/SNVGGishSpeechModel.mlmodelc", "audio", "SoundAnalysis"),
]


# ══════════════════════════════════════════════════════════════════════
# APPLE AI FRAMEWORKS
# ══════════════════════════════════════════════════════════════════════

APPLE_FRAMEWORKS = [
    # ── AIML Infrastructure ──
    ("AIMLExperimentationAnalytics", "aiml-infra"),
    ("AIMLInstrumentationStreams", "aiml-infra"),

    # ── Suggestions ──
    ("AccountSuggestions", "suggestions"),
    ("CoreSuggestions", "suggestions"),
    ("CoreSuggestionsInternals", "suggestions"),
    ("CoreSuggestionsML", "suggestions"),
    ("CoreSuggestionsUI", "suggestions"),
    ("MapsSuggestions", "suggestions"),
    ("Suggestions", "suggestions"),
    ("SuggestionsSpotlightMetrics", "suggestions"),
    ("PeopleSuggester", "suggestions"),
    ("ProactiveML", "suggestions"),
    ("ProactiveSuggestionClientModel", "suggestions"),

    # ── Neural Engine / ML Runtime ──
    ("AppleNeuralEngine", "neural-engine"),
    ("NeuralNetworks", "neural-engine"),
    ("CPMLBestShim", "ml-runtime"),
    ("CipherML", "ml-runtime"),
    ("MLAssetIO", "ml-runtime"),
    ("MLCompilerRuntime", "ml-runtime"),
    ("MLCompilerServices", "ml-runtime"),
    ("MLModelSpecification", "ml-runtime"),
    ("MLRuntime", "ml-runtime"),
    ("CoreMLTestFramework", "ml-runtime"),
    ("LighthouseCoreMLFeatureStore", "ml-runtime"),
    ("LighthouseCoreMLModelAnalysis", "ml-runtime"),
    ("LighthouseCoreMLModelStore", "ml-runtime"),
    ("RemoteCoreML", "ml-runtime"),
    ("MediaML", "ml-runtime"),
    ("MediaMLServices", "ml-runtime"),
    ("SAML", "ml-runtime"),

    # ── Speech / TTS ──
    ("CoreSpeech", "speech"),
    ("CoreSpeechExclave", "speech"),
    ("CoreSpeechFoundation", "speech"),
    ("CoreEmbeddedSpeechRecognition", "speech"),
    ("LocalSpeechRecognitionBridge", "speech"),
    ("LiveSpeechServices", "speech"),
    ("LiveSpeechUI", "speech"),
    ("SpeechDetector", "speech"),
    ("SpeechDictionary", "speech"),
    ("SpeechObjects", "speech"),
    ("SpeechRecognitionCommandServices", "speech"),
    ("SpeechRecognitionCore", "speech"),
    ("SpeechRecognitionSharedSupport", "speech"),
    ("TextToSpeech", "tts"),
    ("TextToSpeechBundleSupport", "tts"),
    ("TextToSpeechKonaSupport", "tts"),
    ("TextToSpeechMauiSupport", "tts"),
    ("TextToSpeechVoiceBankingSupport", "tts"),
    ("TextToSpeechVoiceBankingUI", "tts"),
    ("DataDetectorsNaturalLanguage", "nlp"),

    # ── Apple Intelligence ──
    ("IntelligenceEngine", "apple-intelligence"),
    ("IntelligencePlatform", "apple-intelligence"),
    ("IntelligencePlatformCompute", "apple-intelligence"),
    ("IntelligencePlatformCore", "apple-intelligence"),
    ("IntelligencePlatformLibrary", "apple-intelligence"),
    ("OSIntelligence", "apple-intelligence"),
    ("PersonalIntelligenceCore", "apple-intelligence"),

    # ── Siri ──
    ("SiriActivationFoundation", "siri"),
    ("SiriAnalytics", "siri"),
    ("SiriAppLaunchIntents", "siri"),
    ("SiriAppResolution", "siri"),
    ("SiriAudioIntentUtils", "siri"),
    ("SiriAudioInternal", "siri"),
    ("SiriAudioSnippetKit", "siri"),
    ("SiriAudioSupport", "siri"),
    ("SiriCalendarIntents", "siri"),
    ("SiriCalendarUI", "siri"),
    ("SiriCam", "siri"),
    ("SiriContactsIntents", "siri"),
    ("SiriCore", "siri"),
    ("SiriCoreMetrics", "siri"),
    ("SiriCorrections", "siri"),
    ("SiriCrossDeviceArbitration", "siri"),
    ("SiriCrossDeviceArbitrationFeedback", "siri"),
    ("SiriDailyBriefingInternal", "siri"),
    ("SiriDialogEngine", "siri"),
    ("SiriEmergencyIntents", "siri"),
    ("SiriEntityMatcher", "siri"),
    ("SiriFindMy", "siri"),
    ("SiriFlowEnvironment", "siri"),
    ("SiriFoundation", "siri"),
    ("SiriGeo", "siri"),
    ("SiriHomeAccessoryFramework", "siri"),
    ("SiriIdentityInternal", "siri"),
    ("SiriInCall", "siri"),
    ("SiriInference", "siri"),
    ("SiriInferenceFlow", "siri"),
    ("SiriInferenceIntents", "siri"),
    ("SiriInformationSearch", "siri"),
    ("SiriInformationTypes", "siri"),
    ("SiriInstrumentation", "siri"),
    ("SiriIntentEvents", "siri"),
    ("SiriInteractive", "siri"),
    ("SiriKitFlow", "siri"),
    ("SiriKitInvocation", "siri"),
    ("SiriKitRuntime", "siri"),
    ("SiriLiminal", "siri"),
    ("SiriMailInternal", "siri"),
    ("SiriMailUI", "siri"),
    ("SiriMessageBus", "siri"),
    ("SiriMessageTypes", "siri"),
    ("SiriMessagesCommon", "siri"),
    ("SiriMessagesFlow", "siri"),
    ("SiriMessagesUI", "siri"),
    ("SiriNLUOverrides", "siri"),
    ("SiriNLUTypes", "siri"),
    ("SiriNaturalLanguageGeneration", "siri"),
    ("SiriNaturalLanguageParsing", "siri"),
    ("SiriNetwork", "siri"),
    ("SiriNotebook", "siri"),
    ("SiriNotificationsIntents", "siri"),
    ("SiriObservation", "siri"),
    ("SiriOntology", "siri"),
    ("SiriOntologyProtobuf", "siri"),
    ("SiriPaymentsIntents", "siri"),
    ("SiriPlaybackControlIntents", "siri"),
    ("SiriPlaybackControlSupport", "siri"),
    ("SiriPowerInstrumentation", "siri"),
    ("SiriPrivateLearningAnalytics", "siri"),
    ("SiriPrivateLearningInference", "siri"),
    ("SiriPrivateLearningLogging", "siri"),
    ("SiriReferenceResolution", "siri"),
    ("SiriReferenceResolutionDataModel", "siri"),
    ("SiriReferenceResolver", "siri"),
    ("SiriRemembers", "siri"),
    ("SiriRequestDispatcher", "siri"),
    ("SiriSettingsIntents", "siri"),
    ("SiriSetup", "siri"),
    ("SiriSharedUI", "siri"),
    ("SiriSignals", "siri"),
    ("SiriSocialConversation", "siri"),
    ("SiriSpeechSynthesis", "siri"),
    ("SiriSuggestions", "siri"),
    ("SiriSuggestionsAPI", "siri"),
    ("SiriSuggestionsIntelligence", "siri"),
    ("SiriSuggestionsKit", "siri"),
    ("SiriSuggestionsSupport", "siri"),
    ("SiriTTS", "siri"),
    ("SiriTTSService", "siri"),
    ("SiriTTSTraining", "siri"),
    ("SiriTaskEngagement", "siri"),
    ("SiriTasks", "siri"),
    ("SiriTimeAlarmInternal", "siri"),
    ("SiriTimeInternal", "siri"),
    ("SiriTimeTimerInternal", "siri"),
    ("SiriTranslationIntents", "siri"),
    ("SiriUI", "siri"),
    ("SiriUIBridge", "siri"),
    ("SiriUICore", "siri"),
    ("SiriUIFoundation", "siri"),
    ("SiriUserSegments", "siri"),
    ("SiriUtilities", "siri"),
    ("SiriVOX", "siri"),
    ("SiriVideoIntents", "siri"),
    ("SiriVirtualDeviceResolution", "siri"),
    ("SiriWellnessIntents", "siri"),

    # ── Parsec (Search) ──
    ("CoreParsec", "search"),
    ("ParsecModel", "search"),
    ("ParsecSubscriptionServiceSupport", "search"),

    # ── Knowledge / Vision ──
    ("CoreKnowledge", "knowledge"),
    ("KnowledgeGraphKit", "knowledge"),
    ("KnowledgeMonitor", "knowledge"),
    ("PhotosIntelligence", "vision"),
    ("PhotosKnowledgeGraph", "vision"),
    ("VisionCore", "vision"),
    ("VisionKitCore", "vision"),
    ("VisualIntelligence", "vision"),
    ("SensitiveContentAnalysisML", "vision"),
    ("PostSiriEngagement", "engagement"),
]


def scan_and_register():
    """Scan all Apple AI models and frameworks, register with SHA-2048."""
    registry = ModelRegistry()

    print(f"""
{PINK}╔══════════════════════════════════════════════════════════════╗{RESET}
{PINK}║{RESET}  {WHITE}ROADCHAIN MODEL VERIFICATION{RESET} — {AMBER}SHA-2048{RESET}                   {PINK}║{RESET}
{PINK}║{RESET}  {DIM}identity > provider{RESET}                                        {PINK}║{RESET}
{PINK}╚══════════════════════════════════════════════════════════════╝{RESET}
""")

    # ── Register CoreML Models ──
    print(f"{WHITE}Verifying Apple AI Models (.mlmodelc)...{RESET}")
    print(f"{'─' * 70}")

    model_count = 0
    for name, path, category, framework in APPLE_MODELS:
        exists = Path(path).exists()
        record = registry.register_model(
            name=name,
            path=path,
            model_type="mlmodelc",
            vendor="apple",
            category=category,
            framework=framework,
        )
        status = f"{GREEN}VERIFIED{RESET}" if exists else f"{AMBER}INDEXED{RESET}"
        size_str = f"{record.size_bytes / 1024:.0f}KB" if record.size_bytes > 0 else "---"
        print(f"  {status} {name:<50} {record.short_id}  {size_str}")
        model_count += 1

    print(f"\n{GREEN}{model_count} models registered{RESET}\n")

    # ── Register Frameworks ──
    print(f"{WHITE}Verifying Apple AI Frameworks...{RESET}")
    print(f"{'─' * 70}")

    fw_count = 0
    for name, category in APPLE_FRAMEWORKS:
        # Try both Frameworks and PrivateFrameworks
        fw_path = f"/System/Library/PrivateFrameworks/{name}.framework"
        if not Path(fw_path).exists():
            fw_path = f"/System/Library/Frameworks/{name}.framework"

        record = registry.register_model(
            name=name,
            path=fw_path,
            model_type="framework",
            vendor="apple",
            category=category,
            framework=name,
        )
        exists = Path(fw_path).exists()
        status = f"{GREEN}VERIFIED{RESET}" if exists else f"{AMBER}INDEXED{RESET}"
        print(f"  {status} {name:<50} {record.short_id}")
        fw_count += 1

    print(f"\n{GREEN}{fw_count} frameworks registered{RESET}\n")

    # ── Stats ──
    stats = registry.stats()
    print(f"{PINK}{'═' * 70}{RESET}")
    print(f"{WHITE}SHA-2048 MODEL VERIFICATION COMPLETE{RESET}")
    print(f"{PINK}{'═' * 70}{RESET}")
    print(f"  Total:      {stats['total_models']} models + frameworks")
    print(f"  Verified:   {GREEN}{stats['verified']}{RESET}")
    print(f"  Size:       {stats['total_size_mb']} MB indexed")
    print()
    print(f"  {WHITE}By Vendor:{RESET}")
    for v, c in stats["vendors"].items():
        print(f"    {v:<20} {c}")
    print()
    print(f"  {WHITE}By Type:{RESET}")
    for t, c in stats["types"].items():
        print(f"    {t:<20} {c}")
    print()
    print(f"  {WHITE}By Category:{RESET}")
    for cat, c in stats["categories"].items():
        print(f"    {cat:<24} {c}")
    print()
    print(f"  {DIM}identity > provider — every model has a 2048-bit fingerprint{RESET}")

    registry.close()
    return stats


def show_stats():
    registry = ModelRegistry()
    stats = registry.stats()
    registry.close()

    print(f"{WHITE}Model Registry Stats:{RESET}")
    for k, v in stats.items():
        print(f"  {k}: {v}")


def list_models():
    registry = ModelRegistry()
    records = registry.list_all()
    registry.close()

    print(f"{WHITE}Verified Models ({len(records)}):{RESET}")
    print(f"{'─' * 80}")
    print(f"  {'Name':<45} {'Type':<12} {'ID':<18} {'Category'}")
    print(f"{'─' * 80}")
    for r in records:
        print(f"  {r.name:<45} {r.model_type:<12} {r.short_id:<18} {r.metadata.get('category', '')}")


if __name__ == "__main__":
    args = sys.argv[1:]

    if "--stats" in args:
        show_stats()
    elif "--list" in args:
        list_models()
    elif "--verify" in args:
        print("Re-verifying all models...")
        registry = ModelRegistry()
        records = registry.list_all()
        for r in records:
            ok = registry.verify_model(r.name)
            status = f"{GREEN}OK{RESET}" if ok else f"{RED}CHANGED{RESET}"
            print(f"  {status} {r.name}")
        registry.close()
    else:
        scan_and_register()
