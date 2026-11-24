part of 'file_manager_bloc.dart';

sealed class const FileManagerEvent({
  required super.name,
  super.onError,
  super.onSuccess,
}) extends BaseBlocEvent;

class const FileManagerInitialized({super.onError, super.onSuccess})
    extends FileManagerEvent {
  this : super(name: 'File_Manager_Initialized');

  @override
  Map<String, dynamic> toJson() => {};
}

class const FileManagerNavigateToSegment({
  required final int index,
  super.onSuccess,
  super.onError,
}) extends FileManagerEvent {
  this : super(name: 'File_Manager_Navigate_To_Segment');

  @override
  Map<String, dynamic> toJson() => {'index': index};
}

class const FileManagerOpenDirectory({
  required final String path,
  super.onSuccess,
  super.onError,
}) extends FileManagerEvent {
  this : super(name: 'File_Manager_Open_Directory');

  @override
  Map<String, dynamic> toJson() => {'path': path};
}

class const FileManagerToggleSelection({
  required final String path,
  super.onSuccess,
  super.onError,
}) extends FileManagerEvent {
  this : super(name: 'File_Manager_Toggle_Selection');

  @override
  Map<String, dynamic> toJson() => {'path': path};
}

class const FileManagerSelectAll({super.onSuccess, super.onError})
    extends FileManagerEvent {
  this : super(name: 'File_Manager_Select_All');

  @override
  Map<String, dynamic> toJson() => {};
}

class const FileManagerClearSelection({super.onSuccess, super.onError})
    extends FileManagerEvent {
  this : super(name: 'File_Manager_Clear_Selection');

  @override
  Map<String, dynamic> toJson() => {};
}

class const FileManagerDeleteSelected({super.onSuccess, super.onError})
    extends FileManagerEvent {
  this : super(name: 'File_Manager_Delete_Selected');

  @override
  Map<String, dynamic> toJson() => {};
}
