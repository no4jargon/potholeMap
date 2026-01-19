import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var manager: RecordingManager
    @State private var recordingToRename: Recording?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    recordingsList

                    Spacer(minLength: 24)

                    recorderControls
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            manager.loadRecordings()
        }
        .alert("Rename Recording", isPresented: Binding(
            get: { recordingToRename != nil },
            set: { isPresented in
                if !isPresented {
                    recordingToRename = nil
                }
            }
        )) {
            TextField("Title", text: $renameText)
            Button("Save") {
                if let recording = recordingToRename {
                    manager.renameRecording(recording, to: renameText)
                }
                recordingToRename = nil
            }
            Button("Cancel", role: .cancel) {
                recordingToRename = nil
            }
        } message: {
            Text("Update the name for this road recording.")
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Road Memos")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 28)
        .padding(.bottom, 16)
    }

    private var recordingsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.recordings) { recording in
                    HStack(spacing: 12) {
                        NavigationLink(destination: RecordingDetailView(recording: recording)) {
                            RecordingRow(recording: recording)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        analyzeButton(for: recording)
                    }
                    .padding(.horizontal, 20)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            recordingToRename = recording
                            renameText = recording.title
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            manager.deleteRecording(recording)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.leading, 20)
                }
            }
        }
    }

    private func analyzeButton(for recording: Recording) -> some View {
        let isAnalyzed = manager.analyses[recording.id] != nil
        return Button {
            manager.analyzeRecording(recording)
        } label: {
            Text(isAnalyzed ? "Reanalyze" : "Analyze")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .accessibilityLabel(isAnalyzed ? "Reanalyze recording" : "Analyze recording")
    }

    private var recorderControls: some View {
        VStack(spacing: 12) {
            Text(manager.isRecording ? manager.elapsedTimeString : "Tap to record pothole data")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))

            RecordButton(isRecording: manager.isRecording) {
                if manager.isRecording {
                    manager.stopRecording()
                } else {
                    manager.startRecording()
                }
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}

struct RecordingRow: View {
    let recording: Recording

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .foregroundColor(.white)
                    .font(.headline)
                Text(recording.subtitle)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.subheadline)
            }

            Spacer()

            Text(recording.durationString)
                .foregroundColor(.white.opacity(0.8))
                .font(.subheadline.monospacedDigit())
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    ContentView()
        .environmentObject(RecordingManager())
}
