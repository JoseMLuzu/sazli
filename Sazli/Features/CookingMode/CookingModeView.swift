import SwiftUI

struct CookingModeView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  let recipe: Recipe
  @State private var step = 0
  @State private var showingIngredients = false
  @State private var showingTimer = false
  @State private var showingVoice = false
  @State private var timerStore = CookingTimerStore.shared
  @State private var preparedIngredients: Set<Int> = []
  @State private var screenSession = CookingScreenSession()
  @State private var voice = CookingVoiceController()
  @AppStorage("cookingCommandLanguage") private var commandLanguage = CookingVoiceLanguage.spanish.rawValue
  @AccessibilityFocusState private var stepFocused: Bool

  private var steps: [String] { recipe.instructionLines }
  private var voiceStep: CookingVoiceStep? {
    steps.indices.contains(step) ? CookingVoiceStep(number: step + 1, text: steps[step]) : nil
  }
  private var voiceLanguage: Binding<CookingVoiceLanguage> {
    Binding(get: { CookingVoiceLanguage(rawValue: commandLanguage) ?? .spanish }, set: { commandLanguage = $0.rawValue })
  }

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        let usesColumns =
          geometry.size.width >= SazliLayout.columnBreakpoint
          && !dynamicTypeSize.isAccessibilitySize
        HStack(alignment: .top, spacing: 28) {
          if !steps.isEmpty {
            if usesColumns {
              ingredientsPanel
                .frame(maxWidth: .infinity)
            }
            stepContent
          } else {
            ContentUnavailableView(
              "No steps yet", systemImage: "list.number",
              description: Text("Edit your recipe to add preparation steps."))
          }
        }
        .padding(24)
        .frame(maxWidth: SazliLayout.contentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .background(SazliTheme.background)
      .safeAreaInset(edge: .bottom) {
        if !steps.isEmpty {
          VStack(spacing: 16) {
            if let status = voice.status {
              HStack(spacing: 16) {
                Text(status).font(.caption).foregroundStyle(.secondary)
                  .frame(maxWidth: .infinity, alignment: .leading)
                if voice.readingState == .speaking {
                  Button("Pause", systemImage: "pause.fill") { voice.pauseReading() }
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                } else if voice.readingState == .paused {
                  Button("Resume", systemImage: "play.fill") { voice.resumeReading() }
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
              }
            }
            cookingTools
            navigationButtons
          }
          .frame(maxWidth: SazliLayout.actionWidth)
          .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8)
          .frame(maxWidth: .infinity)
          .background(SazliTheme.background)
        }
      }
      .navigationTitle("Cooking mode").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
      }
      .sheet(isPresented: $showingVoice) {
        NavigationStack {
          ScrollView {
            CookingVoiceControls(voice: voice, language: voiceLanguage)
              .padding(24)
          }
          .background(SazliTheme.background)
          .navigationTitle("Voice assistance").navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") { showingVoice = false }
            }
          }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showingTimer) {
        CookingTimerView(recipeID: recipe.id, recipeTitle: recipe.title, stepNumber: step + 1)
      }
      .sheet(isPresented: $showingIngredients) {
        NavigationStack {
          List {
            if recipe.ingredientLines.isEmpty {
              Text("No ingredients have been added yet.").foregroundStyle(.secondary)
            } else {
              ForEach(Array(recipe.ingredientLines.enumerated()), id: \.offset) { index, line in
                ingredientRow(line, index: index)
              }
            }
          }
          .sazliScreen()
          .navigationTitle("Ingredients").navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") { showingIngredients = false }
            }
          }
        }
      }
      .onAppear {
        voice.onCommand = { command in
          if command == .next { move(by: 1) }
          else if command == .previous { move(by: -1) }
        }
        if scenePhase == .active {
          screenSession.activate()
          voice.activate(step: voiceStep, language: voiceLanguage.wrappedValue)
        }
      }
      .onDisappear { voice.shutdown(); screenSession.restore() }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active {
          screenSession.activate()
          voice.activate(step: voiceStep, language: voiceLanguage.wrappedValue)
        } else {
          screenSession.restore()
          voice.sceneInactive(background: phase == .background)
        }
      }
      .onChange(of: showingTimer) { _, showing in if showing { voice.stopAll() } }
      .onChange(of: showingIngredients) { _, showing in if showing { voice.stopAll() } }
    }
  }

  private var stepContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        VStack(alignment: .leading, spacing: 16) {
          Text(recipe.title)
            .font(.subheadline).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          HStack(alignment: .firstTextBaseline) {
            Text("Step \(step + 1)").font(.title2.weight(.semibold))
            Spacer()
            Text("of \(steps.count)")
              .font(.subheadline).foregroundStyle(.secondary)
          }
          ProgressView(value: Double(step + 1), total: Double(steps.count))
            .tint(SazliTheme.terracotta)
            .accessibilityLabel("Cooking progress")
        }
        RecipeStepCard(number: step + 1, text: steps[step], prominent: true)
          .id(step)
          .accessibilityFocused($stepFocused)
        if timerStore.timer != nil {
          CookingTimerSummary { showingTimer = true }
        }
      }
      .padding(.bottom, 12)
    }
    .defaultScrollAnchor(.top)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var cookingTools: some View {
    HStack(spacing: 8) {
      cookingTool("Ingredients", symbol: "list.bullet", active: false) { showingIngredients = true }
      cookingTool("Timer", symbol: "timer", active: timerStore.timer != nil) { showingTimer = true }
      cookingTool("Voice", symbol: voice.isListening ? "waveform" : "speaker.wave.2",
        active: voice.readAloudEnabled || voice.commandsEnabled) { showingVoice = true }
    }
    .padding(6)
    .recipePanel(cornerRadius: 20)
  }

  private func cookingTool(_ title: String, symbol: String, active: Bool,
    action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol).font(.body.weight(.medium))
        Text(title).font(.caption.weight(.medium)).fixedSize(horizontal: false, vertical: true)
      }
      .foregroundStyle(active ? SazliTheme.terracotta : Color.primary)
      .frame(maxWidth: .infinity, minHeight: 48)
      .padding(.vertical, 4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityValue(active ? "On" : "")
  }

  private var ingredientsPanel: some View {
    VStack(alignment: .leading, spacing: 12) {
      RecipeSectionHeading(
        title: "Ingredients",
        subtitle: "\(preparedIngredients.count) of \(recipe.ingredientLines.count) prepared",
        symbol: "leaf.fill", tint: SazliTheme.olive)
      if !recipe.ingredientLines.isEmpty {
        ProgressView(
          value: Double(preparedIngredients.count), total: Double(recipe.ingredientLines.count)
        )
        .tint(SazliTheme.olive)
        .accessibilityLabel("Ingredients prepared")
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          if recipe.ingredientLines.isEmpty {
            Text("No ingredients have been added yet.").foregroundStyle(.secondary)
          } else {
            ForEach(Array(recipe.ingredientLines.enumerated()), id: \.offset) { index, line in
              ingredientRow(line, index: index)
              if index < recipe.ingredientLines.count - 1 {
                Divider().padding(.leading, 36)
              }
            }
          }
        }
      }
    }
    .padding(20)
    .frame(maxHeight: .infinity, alignment: .top)
    .recipePanel()
    .accessibilityElement(children: .contain)
  }

  private func ingredientRow(_ text: String, index: Int) -> some View {
    IngredientRow(text: text, isPrepared: preparedIngredients.contains(index)) {
      withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
        if preparedIngredients.contains(index) {
          preparedIngredients.remove(index)
        } else {
          preparedIngredients.insert(index)
        }
      }
    }
  }

  private var navigationButtons: some View {
    let layout =
      dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(spacing: 12))
      : AnyLayout(HStackLayout(spacing: 16))
    return layout {
      Button {
        move(by: -1)
      } label: {
        Label("Back", systemImage: "chevron.left")
          .font(.headline).frame(minHeight: 44)
      }
      .buttonStyle(.bordered).disabled(step == 0)
      if step == steps.count - 1 {
        PrimaryButton(title: "Finish cooking", symbol: "checkmark") { dismiss() }
      } else {
        PrimaryButton(title: "Next step", symbol: "chevron.right") { move(by: 1) }
      }
    }
  }

  private func move(by offset: Int) {
    let next = min(max(step + offset, 0), max(steps.count - 1, 0))
    guard next != step else { return }
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
      step = next
    }
    voice.updateStep(voiceStep)
    stepFocused = true
  }
}
