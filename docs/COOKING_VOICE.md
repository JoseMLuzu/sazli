# Cooking voice assistance

Open a saved recipe with instructions, start cooking, then tap **Voice** in the bottom tools row. Both options start off in each cooking session.

- **Read aloud** reads the current step and each newly selected step. Pause, Resume, and Repeat control narration. Reading does not advance the recipe automatically.
- **Voice commands** requests Speech Recognition and microphone permission when enabled. Select Español or English; this selection is remembered.
- Spanish commands: **Siguiente**, **Anterior**, **Repetir**, **Detener**. English commands: **Next**, **Previous**, **Repeat**, **Stop**. An optional “Sazli” prefix is accepted.

Commands listen between readings. Use Pause to interrupt narration; the microphone is suspended while Sazli speaks to avoid interpreting recipe text as a command. Repeat turns reading on. Stop turns both voice options off. Boundary commands stay on the first/last step and never close cooking mode.

The narrator detects English or Spanish recipe text and otherwise uses the selected command language. It reads the stored step without translating or rewriting it. Reading alone does not request microphone permission.

## Privacy and availability

Commands require Apple's local recognition support for the selected language on the current device. Requests explicitly require on-device recognition; an unavailable local recognizer produces a message rather than using a server. Audio is not saved. There is no backend, API key, background audio mode, or third-party dependency. System voice/language assets must be available on the device.

Leaving cooking, opening its ingredients/timer sheets, backgrounding the app, or an audio interruption stops voice assistance and releases audio resources. Reenable the options to continue. First-use permission dialogs may temporarily make the scene inactive; capture waits for the app to become active. Recognition sessions renew while commands remain enabled. Recipes and the existing timer remain independent.

Denied permissions leave reading available. The error offers Open Settings when a permission needs changing; permissions remain under user control.

## Implementation

- `CookingModeView` owns the controller and connects commands to existing step navigation.
- `CookingVoiceControls` presents the separate settings panel, toggles, language, and reading buttons.
- `CookingVoiceController` coordinates permissions, lifecycle, interruption handling, reading/capture exclusion, and stale callbacks.
- `CookingSpeechOutput` wraps AVSpeechSynthesizer; `CookingCommandListener` wraps SFSpeechRecognizer and AVAudioEngine.
- `CookingVoiceCommand` strictly parses supported phrases. Partial commands must remain stable before acting; unrelated prose and numbers are rejected.
- App build settings and the project generator include microphone and Speech Recognition usage descriptions. No SwiftData schema change is needed.

## Verification and manual acceptance

On November 5, 2026, **19 voice tests** and the full **123-test native suite** passed on iPhone 17 Pro / iOS 26.5 using Xcode 27.2. Injected speech/listening fakes verify sequencing, permissions, lifecycle, interruption cleanup, stale results, parsing, and debounce. A native request check verifies the on-device flag and usage descriptions. These checks do not certify real microphone recognition or synthesized audio quality.

A signed generic iOS Release build passed with both extensions. The update was installed on the paired iPhone 15 after retrying a connection reset. Simulator inspection reached the library/editor, then Device Hub returned `noWindowsAvailable` before cooking controls could be reviewed. Final visual and real-audio acceptance remain manual:

1. Start cooking and enable Read aloud. Check the spoken step, Pause, Resume, Repeat, and manual step changes. Verify reading works without microphone permission.
2. Enable commands, grant the system permissions yourself, choose Español, and say each supported command between readings. Repeat with English. Check first/last-step boundaries and unrelated kitchen speech.
3. Enable both options. Verify narration does not trigger navigation and commands resume after reading or Pause.
4. Deny microphone/Speech permission and check unavailable local recognition. Confirm a clear message and continued manual navigation/read-aloud access.
5. Open ingredients/timer, leave cooking, background the app, interrupt audio, and disconnect headphones. Confirm capture stops and does not restart unexpectedly. Reenter cooking with both options off.
6. Check larger text, VoiceOver, light/dark appearance, narrow iPhones, and open Duo layout. Verify recipes and the timer remain intact.

## Apple references

- [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [Require on-device recognition](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition)
- [Check on-device support](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition)
- [Speech authorization](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition)
- [Audio interruptions](https://developer.apple.com/documentation/avfaudio/avaudiosession/interruptionnotification)

## Permission callback regression

A subsequent iPhone crash identified an actor-isolation trap in the Speech authorization callback. Authorization, audio-tap, and recognition callbacks now explicitly support background invocation. The voice suite has 20 passing tests, including production permission completion on a global queue for every authorization state. This extends the initial verification above; real microphone acceptance remains manual.

## Regional recognition support

The language picker represents a language, independently of the saved raw locale identifier. Recognition checks the system's supported regional variants in the same language, preferring supported user languages, then common variants and remaining supported locales. It selects the first available on-device recognizer and retains it for capture. Spanish never falls back to an English recognizer. A short bounded initialization wait precedes reporting unavailable local support.

A native capability-only probe on the paired iPhone 15 confirmed `es-ES` and `es-CL` had no local support, while `es-US`, `es-MX`, `es-419`, and `es-CO` were locally supported and available. The former hard-coded `es-ES` guard blocked commands on this device. The probe requested no microphone access and transcribed no audio. The permanent voice suite now has 23 passing tests, including regional ordering, absent models, service availability, normalization/deduplication, and language boundaries. Real spoken-command acceptance remains manual.

## Narration quality

Read aloud now chooses the highest-quality available native voice in the detected recipe language: Premium, then Enhanced, then the basic voice. Equal-quality voices prefer the user's regional language settings and the system voice, with a stable fallback. Novelty and Personal Voice candidates are excluded; no new authorization is requested. Spanish narration never uses an English voice to obtain higher quality.

Narration uses the native default speaking rate and normal pitch. Original words, punctuation and quantities are retained for the synthesizer's phrasing. Voice availability is checked for each new step, so newly downloaded voices can be picked up without a database change. Sazli does not download voices or send text to an external speech provider.

For a larger quality improvement, download an Enhanced or Premium voice for the recipe language in iPhone Settings > Accessibility > Read & Speak (Spoken Content on older iOS) > Voices. Not every language/region offers every quality. Return to cooking and use Repeat to hear the available voice. Subjective naturalness must be assessed by listening on the device.

References: [Apple voice qualities](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality), [Apple voice configuration](https://support.apple.com/en-ca/111798), [Read & Speak settings](https://support.apple.com/en-ie/guide/iphone/iph406a46ab8/ios).

The paired iPhone 15 native utterance check passed and selected Mónica (es-ES, basic quality). No eligible Enhanced/Premium Spanish voice was available to the app in that check. The test built an utterance without speaking or opening the microphone.
