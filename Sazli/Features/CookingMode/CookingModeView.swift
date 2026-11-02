import SwiftUI

struct CookingModeView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  let recipe: Recipe
  @State private var step = 0
  @State private var showingIngredients = false
  @State private var preparedIngredients: Set<Int> = []
  @State private var screenSession = CookingScreenSession()
  @AccessibilityFocusState private var stepFocused: Bool

  private var steps: [String] { recipe.instructionLines }

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
          navigationButtons
            .frame(maxWidth: SazliLayout.actionWidth)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(SazliTheme.background)
        }
      }
      .navigationTitle("Cooking mode").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showingIngredients = true
          } label: {
            Image(systemName: "list.bullet")
          }.accessibilityLabel("Show ingredients")
        }
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
      .onAppear { if scenePhase == .active { screenSession.activate() } }
      .onDisappear { screenSession.restore() }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active { screenSession.activate() } else { screenSession.restore() }
      }
    }
  }

  private var stepContent: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        Text(recipe.title).font(.headline).fixedSize(horizontal: false, vertical: true)
        Text("Step \(step + 1) of \(steps.count)")
          .font(.subheadline.weight(.semibold)).foregroundStyle(SazliTheme.terracotta)
        ProgressView(value: Double(step + 1), total: Double(steps.count))
          .tint(SazliTheme.terracotta)
          .accessibilityLabel("Cooking progress")
      }
      .padding(18)
      .background(SazliTheme.terracotta.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
      ScrollView {
        RecipeStepCard(number: step + 1, text: steps[step], prominent: true)
          .id(step)
          .accessibilityFocused($stepFocused)
      }
      .defaultScrollAnchor(.top)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
      step = min(max(step + offset, 0), max(steps.count - 1, 0))
    }
    stepFocused = true
  }
}
