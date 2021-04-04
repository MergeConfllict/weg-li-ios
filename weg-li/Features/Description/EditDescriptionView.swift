// Created for weg-li in 2021.

import ComposableArchitecture
import SwiftUI

struct EditDescriptionView: View {
    struct ViewState: Equatable, Hashable {
        let report: Report
        let carType: String
        let carColor: String
        let licensePlate: String
        let blockedOthers: Bool
        let charge: Report.Charge

        init(state: Report) {
            report = state
            carType = state.car.type
            carColor = state.car.color
            licensePlate = state.car.licensePlateNumber
            blockedOthers = state.charge.blockedOthers
            charge = state.charge
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(carType)
            hasher.combine(carColor)
            hasher.combine(licensePlate)
        }
    }

    let store: Store<Report, ReportAction>
    @ObservedObject private var viewStore: ViewStore<ViewState, ReportAction>

    init(store: Store<Report, ReportAction>) {
        self.store = store
        viewStore = ViewStore(store.scope(state: ViewState.init))
    }

    var body: some View {
        Form {
            Section(header: Text(L10n.Description.Section.Vehicle.copy)) {
                TextField(
                    L10n.Description.Row.carType,
                    text: viewStore.binding(
                        get: \.carType,
                        send: { ReportAction.car(.type($0)) }))
                TextField(
                    L10n.Description.Row.carColor,
                    text: viewStore.binding(
                        get: \.carColor,
                        send: { ReportAction.car(.color($0)) }))
                TextField(
                    L10n.Description.Row.licensplateNumber,
                    text: viewStore.binding(
                        get: \.licensePlate,
                        send: { ReportAction.car(.licensePlateNumber($0)) }))
            }
            .padding(.top, 4)
            .textFieldStyle(PlainTextFieldStyle())
            Section(header: Text(L10n.Description.Section.Violation.copy)) {
                Picker(
                    L10n.Description.Row.chargeType,
                    selection: viewStore.binding(
                        get: \.charge.selectedType,
                        send: { ReportAction.charge(.selectCharge($0)) })) {
                        ForEach(0..<Report.Charge.charges.count, id: \.self) {
                            Text(Report.Charge.charges[$0])
                                .tag($0)
                                .foregroundColor(Color(.label))
                        }
                }
                Picker(
                    L10n.Description.Row.length,
                    selection: viewStore.binding(
                        get: \.charge.selectedDuration,
                        send: { ReportAction.charge(.selectDuraration($0)) })) {
                        ForEach(0..<Times.allCases.count, id: \.self) {
                            Text(Times.allCases[$0].description)
                                .foregroundColor(Color(.label))
                        }
                }
                toggleRow
            }
        }
        .navigationBarTitle(Text(L10n.Description.widgetTitle), displayMode: .inline)
    }

    private var toggleRow: some View {
        HStack {
            Text(L10n.Description.Row.didBlockOthers)
            Spacer()
            ToggleButton(
                isOn: viewStore.binding(
                    get: \.charge.blockedOthers,
                    send: { _ in ReportAction.charge(.toggleBlockedOthers) })
            ).animation(.easeIn(duration: 0.1))
        }
    }
}

struct Description_Previews: PreviewProvider {
    static var previews: some View {
        EditDescriptionView(
            store: .init(
                initialState: .init(
                    images: .init(),
                    contact: .preview,
                    location: LocationViewState(storedPhotos: [])),
                reducer: .empty,
                environment: ())
        )
//        .preferredColorScheme(.dark)
        .environment(\.sizeCategory, .extraExtraLarge)
    }
}