//
//  ItemContent.swift
//  Listable
//
//  Created by Kyle Van Essen on 8/10/19.
//


public protocol ItemContent where Coordinator.ItemContentType == Self
{
    //
    // MARK: Identification
    //
    
    /// Identifies the content across updates to the list. This value must remain the same,
    /// otherwise the content will be considered a new item, and the old one removed from the list.
    ///
    /// Does not have to be globally unique – the list will make a "best guess" if there are multiple items
    /// with the same identifier. However, diffing of changes will be more correct with a unique identifier.
    ///
    /// If you're backing your content with some sort of client or server-provided data, consider using its
    /// server or client UUID here, or some other unique identifier from the underlying data model.
    var identifier : Identifier<Self> { get }
    
    //
    // MARK: Default Item Properties
    //
    
    /// Default values to assign to various properties on the `Item` which wraps
    /// this `ItemContent`, if those values are not passed to the `Item` initializer.
    var defaultProperties : DefaultItemProperties<Self> { get }
    
    //
    // MARK: Applying To Displayed View
    //
        
    /**
     Called when rendering the content. This is where you should push data from your
     content into the passed in views.
     
     Do not retain a reference to the passed in views – they are reused by the list.
     */
    func apply(
        to views : ItemContentViews<Self>,
        for reason: ApplyReason,
        with info : ApplyItemContentInfo
    )
    
    //
    // MARK: Tracking Changes
    //
    
    /**
     Return true if the content's sort changed based on the old value passed into the function.
     
     The list view uses the value of this method to be more intelligent about what has moved within the list.
     
     Note
     ----
     There is a default implementation of this method which simply calls `isEquivalent`.
     */
    func wasMoved(comparedTo other : Self) -> Bool
    
    /**
     Return false if the content' changed based on the old value passed into the function.
     
     If this method returns false, the row representing the content is reloaded.
     
     Note
     ----
     There is a default implementation of this method when `ItemContent ` conforms to `Equatable`
     which returns `self == other`.
     */
    func isEquivalent(to other : Self) -> Bool
    
    //
    // MARK: Creating & Providing Swipe Action Views
    //
    
    /// The view type to use to render swipe actions (delete, etc) for this content.
    /// A default implementation, which matches `UITableView`, is provided.
    associatedtype SwipeActionsView: ItemContentSwipeActionsView = DefaultSwipeActionsView
    
    //
    // MARK: Creating & Providing Content Views
    //
    
    /// The content view used to draw the content.
    /// The content view is drawn at the top of the view hierarchy, above the background views.
    associatedtype ContentView:UIView
    

    /// Create and return a new content view used to render the content.
    ///
    /// Note
    /// ----
    /// Do not do configuration in this method that will be changed by your view's theme or appearance – instead
    /// do that work in `apply(to:)`, so the appearance will be updated if the appearance of content changes.
    static func createReusableContentView(frame : CGRect) -> ContentView
    
    //
    // MARK: Content Coordination
    //
    
    /// The coordinator type to use to manage the live state of the `Item` and `ItemContent`,
    /// if you need to update content based on signals such as notifications, view state, appearance state,
    /// etc.
    associatedtype Coordinator : ItemContentCoordinator = DefaultItemContentCoordinator<Self>
    
    /// The actions passed to the coordinator.
    typealias CoordinatorActions = ItemContentCoordinatorActions<Self>
    /// The info passed to the coordinator.
    typealias CoordinatorInfo = ItemContentCoordinatorInfo<Self>
    
    /// Creates a new coordinator with the provided actions and info.
    func makeCoordinator(actions : CoordinatorActions, info : CoordinatorInfo) -> Coordinator
    
    //
    // MARK: Creating & Providing Background Views
    //
    
    /// The background view used to draw the background of the content.
    /// The background view is drawn below the content view.
    ///
    /// Note
    /// ----
    /// Defaults to a `UIView` with no drawn appearance or state.
    /// You do not need to provide this `typealias` unless you would like
    /// to draw a background view.
    ///
    associatedtype BackgroundView:UIView = UIView
    
    /// Create and return a new background view used to render the content's background.
    ///
    /// Note
    /// ----
    /// Do not do configuration in this method that will be changed by your view's theme or appearance – instead
    /// do that work in `apply(to:)`, so the appearance will be updated if the appearance of content changes.
    static func createReusableBackgroundView(frame : CGRect) -> BackgroundView
    
    /// The selected background view used to draw the background of the content when it is selected or highlighted.
    /// The selected background view is drawn below the content view.
    ///
    /// Note
    /// ----
    /// Defaults to a `UIView` with no drawn appearance or state.
    /// You do not need to provide this `typealias` unless you would like
    /// to draw a selected background view.
    ///
    associatedtype SelectedBackgroundView:UIView = BackgroundView
    
    
    /// Create and return a new background view used to render the content's selected background.
    ///
    /// This view is displayed when the content is highlighted or selected.
    ///
    /// If your `BackgroundView` and `SelectedBackgroundView` are the same type, this method
    /// is provided automatically by calling `createReusableBackgroundView`.
    ///
    /// Note
    /// ----
    /// Do not do configuration in this method that will be changed by your view's theme or appearance – instead
    /// do that work in `apply(to:)`, so the appearance will be updated if the appearance of content changes.
    static func createReusableSelectedBackgroundView(frame : CGRect) -> SelectedBackgroundView
}


/// The views owned by the item content, passed to the `apply(to:) method to theme and provide content.`
public struct ItemContentViews<Content:ItemContent>
{
    /// The content view of the content.
    public var content : Content.ContentView
    
    /// The background view of the content.
    public var background : Content.BackgroundView
    
    /// The selected background view of the content.
    /// Displayed when the content is highlighted or selected.
    public var selectedBackground : Content.SelectedBackgroundView
}


/// Information about the current state of the content, which is passed to `apply(to:)`
/// during configuration and preparation for display.
///
/// You can use this information to alter the display of your content, such as changing
/// the background color for highlights and selections, providing different corner styles
/// for different item positions, etc.
public struct ApplyItemContentInfo
{
    /// The state of the `Item` currently displaying the content. Is it highlighted, selected, etc.
    public var state : ItemState
    
    /// The position of the item within its section.
    public var position : ItemPosition
    
    /// Provides access to actions to handle re-ordering the content within the list.
    public var reordering : ReorderingActions
}


/// Provide a default implementation of `isEquivalent(to:)` if the `ItemContent` is `Equatable`.
public extension ItemContent where Self:Equatable
{
    func isEquivalent(to other : Self) -> Bool
    {
        return self == other
    }
}


/// Provides a default implementation of `identifier` when self conforms to Swift's `Identifiable` protocol.
@available(iOS 13.0, *)
public extension ItemContent where Self:Identifiable
{
    var identifier : Identifier<Self> {
        .init(self.id)
    }
}


/// Implement `wasMoved` in terms of `isEquivalent(to:)` by default.
public extension ItemContent
{
    func wasMoved(comparedTo other : Self) -> Bool
    {
        return self.isEquivalent(to: other) == false
    }
}


/// Provide a default implementation of `defaultProperties` which returns an
/// empty instance that does not provide any defaults.
public extension ItemContent
{
    var defaultProperties : DefaultItemProperties<Self> {
        .init()
    }
}


/// Provides a default coordinator for items without a specified coordinator.
public extension ItemContent where Coordinator == DefaultItemContentCoordinator<Self>
{
    func makeCoordinator(actions : ItemContentCoordinatorActions<Self>, info : ItemContentCoordinatorInfo<Self>) -> Coordinator
    {
        DefaultItemContentCoordinator(actions: actions, info: info, view: nil)
    }
}


/// Provide a UIView when no special background view is specified.
public extension ItemContent where BackgroundView == UIView
{
    static func createReusableBackgroundView(frame : CGRect) -> BackgroundView
    {
        BackgroundView(frame: frame)
    }
}


/// Provide a UIView when no special selected background view is specified.
public extension ItemContent where BackgroundView == SelectedBackgroundView
{
    static func createReusableSelectedBackgroundView(frame : CGRect) -> BackgroundView
    {
        self.createReusableBackgroundView(frame: frame)
    }
}


/// Conform to this protocol to implement a completely custom swipe action view.
///
/// If you do so, you're completely responsible for creating and laying out the actions,
/// as well as updating the layout based on the swipe state.
public protocol ItemContentSwipeActionsView: UIView {

    var swipeActionsWidth: CGFloat { get }

    init(didPerformAction: @escaping SwipeAction.CompletionHandler)

    func apply(actions: SwipeActionsConfiguration)

    func apply(state: SwipeActionState)
}
