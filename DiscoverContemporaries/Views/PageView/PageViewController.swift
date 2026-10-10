import SwiftUI
import UIKit

struct PageViewController<Page: View>: UIViewControllerRepresentable {
    var pages: [Page]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        return controller
    }

    func updateUIViewController(
        _ pageViewController: UIPageViewController,
        context: Context
    ) {
        let coordinator = context.coordinator
        coordinator.parent = self

        if coordinator.controllers.count != pages.count {
            coordinator.controllers = pages.map {
                UIHostingController(rootView: $0)
            }
        } else {
            // Keep existing hosting controllers up to date.
            for (controller, page) in zip(
                coordinator.controllers,
                pages
            ) {
                controller.rootView = page
            }
        }

        guard !coordinator.controllers.isEmpty else {
            if pageViewController.viewControllers?.isEmpty == false {
                pageViewController.setViewControllers(
                    nil,
                    direction: .forward,
                    animated: false
                )
            }
            return
        }

        let safeIndex = min(
            max(currentPage, 0),
            coordinator.controllers.count - 1
        )

        let targetController = coordinator.controllers[safeIndex]

        // Avoid resetting the page when it is already visible.
        guard
            pageViewController.viewControllers?.first
                !== targetController
        else {
            return
        }

        let currentIndex = pageViewController.viewControllers?
            .first
            .flatMap { visibleController in
                coordinator.controllers.firstIndex {
                    $0 === visibleController
                }
            } ?? 0

        let direction: UIPageViewController.NavigationDirection =
            safeIndex >= currentIndex ? .forward : .reverse

        pageViewController.setViewControllers(
            [targetController],
            direction: direction,
            animated: false
        )

    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource,
        UIPageViewControllerDelegate
    {

        var parent: PageViewController
        var controllers: [UIHostingController<Page>] = []

        init(_ parent: PageViewController) {
            self.parent = parent
            self.controllers = parent.pages.map {
                UIHostingController(rootView: $0)
            }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {

            guard controllers.count > 1,
                let index = controllers.firstIndex(
                    where: { $0 === viewController }
                )
            else {
                return nil
            }

            let previousIndex =
                (index - 1 + controllers.count) % controllers.count

            return controllers[previousIndex]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {

            guard controllers.count > 1,
                let index = controllers.firstIndex(
                    where: { $0 === viewController }
                )
            else {
                return nil
            }

            let nextIndex = (index + 1) % controllers.count

            return controllers[nextIndex]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                let visibleController =
                    pageViewController.viewControllers?.first,
                let index = controllers.firstIndex(
                    where: { $0 === visibleController }
                )
            else {
                return
            }

            parent.currentPage = index
        }
    }
}
